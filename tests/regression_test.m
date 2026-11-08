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
addpath(fullfile(root, 'src'));   % psl.* packages (+io/+mesh/+stress/+trace/+topology/+vis)

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

% Prepare report directories: latest/ + timestamped archive/, each with a
% snapshots/ subfolder for per-case PSL figures.
[latestDir, archDir] = setupReportDirs(fullfile(root, 'report'));
snapLatest = fullfile(latestDir, 'snapshots');
snapArch   = fullfile(archDir,   'snapshots');

runtests = 0;
for c = 1:total
    cid = cases{c};
    t0 = tic;
    err = ''; maxErr = 0; ok = true;
    snapPath = fullfile(snapLatest, [cid '_psls.png']);
    try
        runCase(root, cid, snapPath);
        if exist(archDir, 'dir')
            copyfile(snapPath, fullfile(snapArch, [cid '_psls.png']));
        end
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

% Write report triple: summary.json (pretty), regression.xml (JUnit), index.html
writeReport(fullfile(root, 'report'), results, npass, runtests);

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
function runCase(root, cid, snapPath)
cc = lookupCase(root, cid);
clear global;
PSLshell(fullfile(root, 'data', cc.file), cc.profile, ...
    struct('showProblem', 0, 'showPSLs', 1, 'saveFig', snapPath));
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

function [latest, arch] = setupReportDirs(reportRoot)
if ~exist(reportRoot, 'dir'), mkdir(reportRoot); end
ts = datestr(now, 'yyyymmddTHHMMSS');
latest = fullfile(reportRoot, 'latest');
arch   = fullfile(reportRoot, ts);
if ~exist(latest, 'dir'), mkdir(latest); end
if ~exist(arch, 'dir'), mkdir(arch); end
if ~exist(fullfile(latest, 'snapshots'), 'dir'), mkdir(fullfile(latest, 'snapshots')); end
if ~exist(fullfile(arch, 'snapshots'), 'dir'), mkdir(fullfile(arch, 'snapshots')); end
end

function writeReport(reportRoot, results, npass, runtests)
[latest, arch] = setupReportDirs(reportRoot);

s = struct();
s.generatedAt = datestr(now, 31);
s.matlabVersion = version;
s.total = runtests;
s.passed = npass;
s.failed = runtests - npass;
s.cases = results;

% Pretty-printed, multi-line JSON (readable in VS Code / any editor).
writeJson(fullfile(latest, 'summary.json'), s);
writeJson(fullfile(arch, 'summary.json'), s);

% JUnit XML (CI-consumable).
xml = junitXml(results, runtests, npass);
writeText(fullfile(latest, 'regression.xml'), xml);
writeText(fullfile(arch, 'regression.xml'), xml);

% Self-contained HTML report with per-case PSL figures.
writeText(fullfile(latest, 'index.html'), buildHtmlReport(s));
writeText(fullfile(arch, 'index.html'), buildHtmlReport(s));

fprintf('Report written to %s\n', latest);
end

function writeJson(path, s)
% Pretty-printed JSON via pjson.m (R2019b-compatible).
writeText(path, [pjson(s) newline]);
end

function writeText(path, str)
fid = fopen(path, 'w');
if fid < 0, error('Cannot write %s', path); end
fprintf(fid, '%s', str);
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

function html = buildHtmlReport(s)
% buildHtmlReport - render a self-contained HTML report with per-case cards.
% Each card shows the PSL snapshot figure, pass/fail badge, maxL1err, duration.
n = numel(s.cases);
cards = cell(1, n);
for i = 1:n
    c = s.cases(i);
    if c.passed
        badge = '<span class="badge pass">PASS</span>';
    else
        badge = '<span class="badge fail">FAIL</span>';
    end
    errRow = '';
    if ~c.passed && ~isempty(c.errWhere)
        errRow = ['<div class="errdetail">' htmlEsc(c.errWhere) '</div>'];
    end
    cards{i} = sprintf([ ...
        '    <div class="card">\n' ...
        '      <div class="card-head">%s %s</div>\n' ...
        '      <img src="snapshots/%s_psls.png" alt="%s" loading="lazy">\n' ...
        '      <div class="card-meta">\n' ...
        '        <span>maxL1err: <b>%.3e</b></span>\n' ...
        '        <span>%.2fs</span>\n' ...
        '      </div>\n' ...
        '      %s\n' ...
        '    </div>'], ...
        htmlEsc(c.caseId), badge, htmlEsc(c.caseId), htmlEsc(c.caseId), ...
        c.maxL1err, c.duration, errRow);
end

html = [ ...
    '<!DOCTYPE html>' newline ...
    '<html lang="zh-CN">' newline ...
    '<head>' newline ...
    '<meta charset="UTF-8">' newline ...
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">' newline ...
    '<title>PSLshell 回归测试报告</title>' newline ...
    '<style>' newline ...
    '  :root{--bg:#f5f6f8;--card:#fff;--ink:#1a1a1a;--muted:#6b7280;--border:#e5e7eb;--pass:#16a34a;--fail:#dc2626;}' newline ...
    '  *{box-sizing:border-box;} body{margin:0;font-family:-apple-system,"Segoe UI","PingFang SC","Microsoft YaHei",sans-serif;background:var(--bg);color:var(--ink);}' newline ...
    '  header{padding:24px 32px 8px;} header h1{margin:0 0 6px;font-size:20px;} header p{margin:0;color:var(--muted);font-size:13px;}' newline ...
    '  .stats{display:flex;gap:20px;padding:8px 32px 4px;font-size:14px;} .stats b{font-size:18px;}' newline ...
    '  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:16px;padding:12px 32px 40px;}' newline ...
    '  .card{background:var(--card);border:1px solid var(--border);border-radius:10px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,.05);}' newline ...
    '  .card img{width:100%;height:230px;object-fit:cover;display:block;background:#fff;}' newline ...
    '  .card-head{font-weight:600;font-size:14px;padding:10px 12px 6px;}' newline ...
    '  .card-meta{display:flex;justify-content:space-between;padding:0 12px 10px;font-size:12px;color:var(--muted);}' newline ...
    '  .badge{display:inline-block;padding:1px 8px;border-radius:999px;font-size:11px;margin-left:6px;color:#fff;}' newline ...
    '  .pass{background:var(--pass);} .fail{background:var(--fail);}' newline ...
    '  .errdetail{font-size:11px;color:var(--fail);padding:0 12px 10px;word-break:break-all;}' newline ...
    '</style>' newline ...
    '</head>' newline ...
    '<body>' newline ...
    '<header><h1>PSLshell 回归测试报告</h1><p>生成时间 ' htmlEsc(s.generatedAt) ' · MATLAB ' htmlEsc(s.matlabVersion) '</p></header>' newline ...
    '<div class="stats">' newline ...
    sprintf('  <div>总计 <b>%d</b></div>\n  <div>通过 <b style="color:var(--pass)">%d</b></div>\n  <div>失败 <b style="color:var(--fail)">%d</b></div>\n', s.total, s.passed, s.failed) ...
    '</div>' newline ...
    '<div class="grid">' newline ...
    strjoin(cards, newline) newline ...
    '</div>' newline ...
    '</body>' newline ...
    '</html>' newline ...
    ];
end

function s = htmlEsc(s)
s = strrep(s, '&', '&amp;');
s = strrep(s, '<', '&lt;');
s = strrep(s, '>', '&gt;');
s = strrep(s, '"', '&quot;');
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