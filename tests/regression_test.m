function regression_test(caseIds)
%% Regression test: re-run current code and compare against baseline anchors.
%%
%% Usage:
%%   regression_test            -> all 19 cases
%%   regression_test('cylinder_Q4') -> single case
%%   regression_test({'cylinder_Q4','plate_bottom'}) -> subset
%%
%% L0 (topological invariants, strict equality):
%%   - major/minor PSL counts, per-PSL numIntergPts
%%   - degenerate point count, per-degept eleIndex and sign(delta)
%% L1 (geometry, 1e-9 relative tolerance):
%%   - per-PSL phyCoordList
%%   - per-degept phyCoord / paraCoord
%%   - per-degept major/minor skeleton phyCoordList
%%
%% Report artifacts under report/latest/ + timestamped archive:
%%   summary.json + regression.xml (JUnit)

root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'baseline'));

cases = defCaseIds();
if nargin >= 1 && ~isempty(caseIds)
    if ischar(caseIds) || isstring(caseIds), caseIds = {char(caseIds)}; end
    cases = caseIds;
end
total = numel(cases);
results = struct('caseId', cell(1,total), 'passed', num2cell(false(1,total)), ...
    'maxL1err', num2cell(zeros(1,total)), 'errWhere', cell(1,total), 'duration', num2cell(zeros(1,total)));

tolAbs = 1e-9; tolRel = 1e-9;
set(0, 'DefaultFigureVisible', 'off');

runtests = 0;
for c = 1:total
    cid = cases{c};
    t0 = tic;
    err = ''; maxErr = 0; ok = true;
    try
        runCase(root, cid);
        load(fullfile(root, 'baseline', [cid '_major.mat']), 'numPSLs', 'numPts', 'coords');
        bMajor = struct('numPSLs', numPSLs, 'numPts', numPts, 'coords', {coords});
        load(fullfile(root, 'baseline', [cid '_minor.mat']), 'numPSLs', 'numPts', 'coords');
        bMinor = struct('numPSLs', numPSLs, 'numPts', numPts, 'coords', {coords});
        load(fullfile(root, 'baseline', [cid '_degepts.mat']));
        bDege = struct('numDegPts', numDegPts, 'eleIndex', eleIndex, 'deltaSign', deltaSign, ...
            'phyCoord', phyCoord, 'paraCoord', paraCoord, 'majorSkel', {majorSkel}, 'minorSkel', {minorSkel});

        global state_;
        majorPSLpool = state_.majorPSLpool_;
        minorPSLpool = state_.minorPSLpool_;
        degePts      = state_.degePts_;
        [okMajor, eMajor, mMajor] = cmpPool(majorPSLpool, bMajor, 'major', tolAbs, tolRel);
        [okMinor, eMinor, mMinor] = cmpPool(minorPSLpool, bMinor, 'minor', tolAbs, tolRel);
        [okDege,  eDege,  mDege ] = cmpDege(degePts, bDege, tolAbs, tolRel);

        ok = okMajor && okMinor && okDege;
        maxErr = max([mMajor mMinor mDege]);
        if ~ok
            err = sprintf('major:%s minor:%s dege:%s', eMajor, eMinor, eDege);
        end
    catch ME
        ok = false;
        err = sprintf('EXC:%s', ME.message);
    end
    % Release the per-case state handle to avoid accumulation across cases.
    try %#ok<TRYNC>
        global state_;
        if ~isempty(state_), delete(state_); end
        clear state_;
    end
    results(c).caseId = cid;
    results(c).passed = ok;
    results(c).maxL1err = maxErr;
    results(c).errWhere = err;
    results(c).duration = toc(t0);
    runtests = runtests + 1;
    fprintf('[%2d/%2d] %-24s %s  maxErr=%.3e  %s\n', c, total, cid, ...
        iif(ok, 'PASS', 'FAIL'), maxErr, err);
end

% Summary
npass = sum([results.passed]);
fprintf('\nRegression: %d/%d passed\n', npass, runtests);

% Write summary.json
writeSummary(fullfile(root, 'report'), results, npass, runtests);

% Assert overall (throw if any failed, so caller/CI sees non-zero exit).
if npass < runtests
    failedIds = {results(~[results.passed]).caseId};
    error('Regression FAILED: %d/%d passed. Failed: %s', ...
        npass, runtests, strjoin(failedIds, ', '));
end

% Ensure clean exit for -batch mode: release figures and global state.
close all;
try %#ok<TRYNC>
    global state_;
    if ~isempty(state_), delete(state_); end
    clear state_;
end
clear global;
clear functions;

% Force-exit ONLY when running under `matlab -batch`, to bypass any Java VM
% shutdown delay that leaves the -batch process hanging after work completes.
% In interactive / MCP sessions (unlikely to run this full script) we do NOT
% exit, so the caller keeps its workspace.
if batchStartupOptionUsed
    exit(0);
end
end

%% ---------------------------------------------------------------------------
function runCase(root, cid)
cc = lookupCase(root, cid);
clear global;
PSLshell(fullfile(root, 'data', cc.file), cc.profile, ...
    struct('showProblem', 0, 'showPSLs', 0, 'saveFig', ''));
end

function [ok, err, maxErr] = cmpPool(pool, base, label, tolAbs, tolRel)
ok = true; err = ''; maxErr = 0;
if numel(pool) ~= base.numPSLs
    ok = false; err = sprintf('%s count %d!=%d', label, numel(pool), base.numPSLs);
    return;
end
for i = 1:numel(pool)
    if pool(i).numIntergPts ~= base.numPts(i)
        ok = false;
        err = sprintf('%s[%d].numPts %d!=%d', label, i, pool(i).numIntergPts, base.numPts(i));
        return;
    end
    [e, m] = cmpVec(pool(i).phyCoordList, base.coords{i}, tolAbs, tolRel);
    maxErr = max(maxErr, m);
    if e > tolAbs
        ok = false;
        err = sprintf('%s[%d].coords maxErr=%.3e', label, i, m);
        return;
    end
end
end

function [ok, err, maxErr] = cmpDege(dege, base, tolAbs, tolRel)
ok = true; err = ''; maxErr = 0;
if numel(dege) ~= base.numDegPts
    ok = false; err = sprintf('dege count %d!=%d', numel(dege), base.numDegPts);
    return;
end
for i = 1:numel(dege)
    if dege(i).eleIndex ~= base.eleIndex(i)
        ok = false; err = sprintf('dege[%d].eleIndex %d!=%d', i, dege(i).eleIndex, base.eleIndex(i)); return;
    end
    if sign(dege(i).delta) ~= base.deltaSign(i)
        ok = false; err = sprintf('dege[%d].sign(delta) %+d!=%+d', i, sign(dege(i).delta), base.deltaSign(i)); return;
    end
    [e1, m1] = cmpVec(dege(i).phyCoord, base.phyCoord(i,:), tolAbs, tolRel);
    [e2, m2] = cmpVec(dege(i).paraCoord, base.paraCoord(i,:), tolAbs, tolRel);
    maxErr = max(maxErr, max(m1, m2));
    if e1 > tolAbs || e2 > tolAbs
        ok = false; err = sprintf('dege[%d] coord err', i); return;
    end
    [okS, eS, mS] = cmpSkel(dege(i).majorSkeletons, base.majorSkel{i}, 'majorSkel', i, tolAbs, tolRel);
    if ~okS, ok = false; err = eS; return; end
    maxErr = max(maxErr, mS);
    [okS, eS, mS] = cmpSkel(dege(i).minorSkeletons, base.minorSkel{i}, 'minorSkel', i, tolAbs, tolRel);
    if ~okS, ok = false; err = eS; return; end
    maxErr = max(maxErr, mS);
end
end

function [ok, err, maxErr] = cmpSkel(skels, baseCell, label, di, tolAbs, tolRel)
ok = true; err = ''; maxErr = 0;
if numel(skels) ~= numel(baseCell)
    ok = false; err = sprintf('dege[%d].%s count %d!=%d', di, label, numel(skels), numel(baseCell));
    return;
end
for j = 1:numel(skels)
    [e, m] = cmpVec(skels(j).phyCoordList, baseCell{j}, tolAbs, tolRel);
    maxErr = max(maxErr, m);
    if e > tolAbs
        ok = false; err = sprintf('dege[%d].%s[%d] coord err', di, label, j);
        return;
    end
end
end

function [maxErr, maxCoordErr] = cmpVec(a, b, tolAbs, tolRel)
% Returns max error as: max absolute coord difference (used for tolerance
% check) and a norm-based error for reporting.
maxErr = 0; maxCoordErr = 0;
if isempty(a) && isempty(b), return; end
a = double(a); b = double(b);
if ~isequal(size(a), size(b))
    maxErr = inf; maxCoordErr = inf; return;
end
d = a - b;
maxCoordErr = max(abs(d(:)));
% norm-based per-point error
n = sqrt(sum(d.^2, 2));
maxErr = max(n);
end

function writeSummary(reportRoot, results, npass, runtests)
if ~exist(reportRoot, 'dir'), mkdir(reportRoot); end
ts = datestr(now, 30); ts = strrep(ts, ':', '-');
latest = fullfile(reportRoot, 'latest'); arch = fullfile(reportRoot, ts);
if ~exist(latest, 'dir'), mkdir(latest); end
if ~exist(arch, 'dir'), mkdir(arch); end

s = struct();
s.generatedAt = datestr(now, 31);
s.matlabVersion = version;
s.total = runtests;
s.passed = npass;
s.failed = runtests - npass;
s.cases = results;
writeJson(fullfile(latest, 'summary.json'), s);
writeJson(fullfile(arch, 'summary.json'), s);

% Minimal JUnit XML (CI-consumable).
xml = junitXml(results, runtests, npass);
fid = fopen(fullfile(latest, 'regression.xml'), 'w');
fprintf(fid, '%s', xml); fclose(fid);
fid = fopen(fullfile(arch, 'regression.xml'), 'w');
fprintf(fid, '%s', xml); fclose(fid);
fprintf('Report written to %s\n', latest);
end

function writeJson(path, s)
fid = fopen(path, 'w');
if fid < 0, error('Cannot write %s', path); end
fprintf(fid, '%s\n', jsonencode(s));
fclose(fid);
end

function xml = junitXml(results, total, npass)
xml = sprintf('<?xml version="1.0" encoding="UTF-8"?>\n<testsuite name="PSLshell-regression" tests="%d" failures="%d">\n', total, total-npass);
for i = 1:numel(results)
    st = results(i);
    if st.passed
        xml = [xml sprintf('  <testcase name="%s" time="%.3f"/>\n', st.caseId, st.duration)]; %#ok<AGROW>
    else
        xml = [xml sprintf('  <testcase name="%s" time="%.3f">\n    <failure>%s</failure>\n  </testcase>\n', ...
            st.caseId, st.duration, escapeXml(st.errWhere))]; %#ok<AGROW>
    end
end
xml = [xml sprintf('</testsuite>\n')];
end

function s = escapeXml(s)
s = strrep(s, '&', '&amp;');
s = strrep(s, '<', '&lt;');
s = strrep(s, '>', '&gt;');
end

function cids = defCaseIds()
cids = { ...
    'cylinder_Q4','cylinder_Q4_global','cylinder_Q8','cylinder_T3','cylinder_T6', ...
    'cylinder_hybrid_Q4T3','cylinder_hybrid_Q8T6','plate_bottom','plate_top','wind_blade', ...
    'hemisphere','polyhedra','wing','dome','snail', ...
    'tpms_diamond','tpms_groid','tpms_neovius','tpms_schwarzP'};
end

function cc = lookupCase(root, cid)
% Same registry as generate_baseline.m (single source of truth stays there;
% this is a lightweight re-declaration to avoid coupling file dependencies.)
P = @(d, m, its) struct('PSLsDensityCtrl', d, 'PSLtypeCtrl', [0 0], ...
    'topologyAware', 1, 'distanceMetric', m, 'seedSparsityCtrl', 1, 'maxIts', its);
raw = { ...
    'cylinder_Q4','cylinder_1_Q4',P(10,'Euclidean',1000); ...
    'cylinder_Q4_global','cylinder_1_Q4_global',P(10,'Euclidean',1000); ...
    'cylinder_Q8','cylinder_1_Q8',P(10,'Euclidean',1000); ...
    'cylinder_T3','cylinder_1_T3',P(10,'Euclidean',1000); ...
    'cylinder_T6','cylinder_1_T6',P(10,'Euclidean',1000); ...
    'cylinder_hybrid_Q4T3','cylinder_1_hybrid_Q4T3',P(10,'Euclidean',1000); ...
    'cylinder_hybrid_Q8T6','cylinder_1_hybrid_Q8T6',P(10,'Euclidean',1000); ...
    'plate_bottom','E1_plate_T3_bottom',P(30,'Euclidean',1000); ...
    'plate_top','E1_plate_T3_top',P(30,'Euclidean',1000); ...
    'hemisphere','E2_hemiSphere_Q8',P(10,'Euclidean',1000); ...
    'polyhedra','E3_Polyhedra_T6',P(15,'Euclidean',1000); ...
    'wing','E4_wing_T6',P(3,'Geodesic',2000); ...
    'wind_blade','E5_wind_blade_T3',P(5,'Geodesic',2000); ...
    'dome','E6_dome_Q8',P(10,'Euclidean',1000); ...
    'snail','E7_snail_T3',P(10,'Euclidean',1000); ...
    'tpms_diamond','E8_TPMS_Diamond',P(40,'Euclidean',2000); ...
    'tpms_groid','E8_TPMS_Groid',P(40,'Euclidean',2000); ...
    'tpms_neovius','E8_TPMS_Neovius',P(40,'Euclidean',2000); ...
    'tpms_schwarzP','E8_TPMS_SchwarzP',P(40,'Euclidean',2000); ...
    };
idx = find(strcmp(raw(:,1), cid), 1);
cc = struct('file', raw{idx,2}, 'profile', raw{idx,3});
end

function v = iif(cond, a, b)
if cond, v = a; else, v = b; end
end