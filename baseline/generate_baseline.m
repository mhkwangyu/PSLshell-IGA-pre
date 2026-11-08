function generate_baseline(caseIds)
%% Generate regression baseline + snapshot figure for each case.
%%
%% Usage:
%%   generate_baseline                  -> all 19 cases
%%   generate_baseline('cylinder_q4')   -> single case id
%%   generate_baseline({'cylinder_q4','plate_bottom'}) -> subset
%%
%% Outputs per case (into baseline/):
%%   <caseId>_major.mat   - major PSL L0/L1 anchors
%%   <caseId>_minor.mat   - minor PSL L0/L1 anchors
%%   <caseId>_degepts.mat - degenerate point L0/L1 anchors
%%   <caseId>_meta.json   - provenance (profile, data file, MATLAB version, ts)
%%   snapshots/<caseId>_psls.png - 300dpi PSL trace figure

root = fileparts(fileparts(mfilename('fullpath')));  % repo root
addpath(fullfile(root, 'src'));   % psl.* packages
cases = defineCases();

if nargin < 1 || isempty(caseIds), caseIds = {cases.id}; end
if ischar(caseIds) || isstring(caseIds), caseIds = {char(caseIds)}; end

baselineDir = fullfile(root, 'baseline');
snapDir = fullfile(baselineDir, 'snapshots');
if ~exist(snapDir, 'dir'), mkdir(snapDir); end

% Headless rendering for batch snapshot generation.
set(0, 'DefaultFigureVisible', 'off');

for c = 1:numel(caseIds)
    cid = char(caseIds{c});
    idx = find(strcmp({cases.id}, cid), 1);
    if isempty(idx)
        warning('Case id "%s" not found, skipped.', cid); continue;
    end
    cc = cases(idx);

    tsFile = fullfile(root, 'data', cc.file);   % without .TSV extension
    if ~exist([tsFile '.TSV'], 'file')
        warning('Data file missing: %s, skipped.', [tsFile '.TSV']); continue;
    end

    fprintf('\n===== [%d/%d] %s =====\n', c, numel(caseIds), cid);
    fprintf('  data: %s\n', tsFile);

    t0 = tic;
    clear global;
    PSLshell(tsFile, cc.profile, struct('showProblem', 0, 'showPSLs', 1, ...
        'saveFig', fullfile(snapDir, [cid '_psls.png'])));

    % Read back results via the shared state handle.
    global state_;
    snapMajor = extractPSLPool(state_.majorPSLpool_);
    snapMinor = extractPSLPool(state_.minorPSLpool_);
    snapDege  = extractDegePts(state_.degePts_);

    save(fullfile(baselineDir, [cid '_major.mat']), '-struct', 'snapMajor', '-v7');
    save(fullfile(baselineDir, [cid '_minor.mat']), '-struct', 'snapMinor', '-v7');
    save(fullfile(baselineDir, [cid '_degepts.mat']), '-struct', 'snapDege', '-v7');

    meta = struct();
    meta.caseId = cid;
    meta.dataFile = [cc.file '.TSV'];
    meta.profile = cc.profile;
    meta.matlabVersion = version;
    meta.generatedAt = datestr(now, 31);
    meta.numMajorPSLs = snapMajor.numPSLs;
    meta.numMinorPSLs = snapMinor.numPSLs;
    meta.numDegPts = snapDege.numDegPts;
    writeMetaJson(fullfile(baselineDir, [cid '_meta.json']), meta);

    fprintf('  major=%d minor=%d dege=%d  (%0.2fs)\n', ...
        snapMajor.numPSLs, snapMinor.numPSLs, snapDege.numDegPts, toc(t0));
end
fprintf('\nAll done.\n');
end

%% ---------------------------------------------------------------------------
function snap = extractPSLPool(pool)
%% Serialize one PSL pool (major or minor) to L0/L1 anchors.
snap = struct();
snap.numPSLs = numel(pool);
n = snap.numPSLs;
snap.numPts = zeros(1, n);      % L0: per-PSL integration point count
snap.coords = cell(1, n);       % L1: full phyCoordList per PSL
for i = 1:n
    snap.numPts(i) = pool(i).numIntergPts;
    snap.coords{i} = pool(i).phyCoordList;
end
end

function snap = extractDegePts(degePts_)
%% Serialize degenerate points to L0/L1 anchors.
snap = struct();
n = numel(degePts_);
snap.numDegPts = n;
snap.eleIndex   = zeros(1, n);   % L0: element index (strict)
snap.deltaSign  = zeros(1, n);   % L0: sign(delta) -> Trisector/Wedge (strict)
snap.phyCoord   = zeros(n, 3);   % L1: physical coordinate
snap.paraCoord  = zeros(n, 2);   % L1: natural coordinate
snap.majorSkel  = cell(1, n);    % L1: major skeleton per tangent
snap.minorSkel  = cell(1, n);    % L1: minor skeleton per tangent
for i = 1:n
    snap.eleIndex(i)  = degePts_(i).eleIndex;
    snap.deltaSign(i) = sign(degePts_(i).delta);
    if isempty(degePts_(i).phyCoord)
        snap.phyCoord(i, :) = NaN;
    else
        snap.phyCoord(i, :) = degePts_(i).phyCoord;
    end
    if isempty(degePts_(i).paraCoord)
        snap.paraCoord(i, :) = NaN;
    else
        snap.paraCoord(i, :) = degePts_(i).paraCoord;
    end
    snap.majorSkel{i} = skelCoords(degePts_(i).majorSkeletons);
    snap.minorSkel{i} = skelCoords(degePts_(i).minorSkeletons);
end
end

function c = skelCoords(skels)
%% Collect phyCoordList of each skeleton PSL into a cell array.
if isempty(skels), c = {}; return; end
c = cell(1, numel(skels));
for j = 1:numel(skels)
    c{j} = skels(j).phyCoordList;
end
end

function writeMetaJson(path, meta)
%% Write provenance as JSON via jsonencode (R2016b+ built-in).
s = jsonencode(meta);
fid = fopen(path, 'w');
if fid < 0, error('Cannot open for write: %s', path); end
fprintf(fid, '%s\n', s);
fclose(fid);
end

function cases = defineCases()
%% Case registry: id + legacy data file + paper-replication profile.
P = @(d, m, its) struct('PSLsDensityCtrl', d, 'PSLtypeCtrl', [0 0], ...
    'topologyAware', 1, 'distanceMetric', m, 'seedSparsityCtrl', 1, 'maxIts', its);

raw = {
    % {caseId, file, profile}
    'cylinder_Q4',        'cylinder_1_Q4',        P(10, 'Euclidean', 1000);
    'cylinder_Q4_global', 'cylinder_1_Q4_global', P(10, 'Euclidean', 1000);
    'cylinder_Q8',        'cylinder_1_Q8',        P(10, 'Euclidean', 1000);
    'cylinder_T3',        'cylinder_1_T3',        P(10, 'Euclidean', 1000);
    'cylinder_T6',        'cylinder_1_T6',        P(10, 'Euclidean', 1000);
    'cylinder_hybrid_Q4T3','cylinder_1_hybrid_Q4T3', P(10, 'Euclidean', 1000);
    'cylinder_hybrid_Q8T6','cylinder_1_hybrid_Q8T6', P(10, 'Euclidean', 1000);
    'plate_bottom',       'E1_plate_T3_bottom',   P(30, 'Euclidean', 1000);
    'plate_top',          'E1_plate_T3_top',      P(30, 'Euclidean', 1000);
    'hemisphere',         'E2_hemiSphere_Q8',     P(10, 'Euclidean', 1000);
    'polyhedra',          'E3_Polyhedra_T6',      P(15, 'Euclidean', 1000);
    'wing',               'E4_wing_T6',           P(3,  'Geodesic',  2000);
    'wind_blade',         'E5_wind_blade_T3',     P(5,  'Geodesic',  2000);
    'dome',               'E6_dome_Q8',           P(10, 'Euclidean', 1000);
    'snail',              'E7_snail_T3',          P(10, 'Euclidean', 1000);
    'tpms_diamond',       'E8_TPMS_Diamond',      P(40, 'Euclidean', 2000);
    'tpms_groid',         'E8_TPMS_Groid',        P(40, 'Euclidean', 2000);
    'tpms_neovius',       'E8_TPMS_Neovius',      P(40, 'Euclidean', 2000);
    'tpms_schwarzP',      'E8_TPMS_SchwarzP',     P(40, 'Euclidean', 2000);
};

cases = struct('id', raw(:,1), 'file', raw(:,2), 'profile', raw(:,3));
end