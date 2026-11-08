function s = pjson(obj, indent)
%PJSON  Encode a MATLAB value as pretty-printed, indented, multi-line JSON.
%
%   s = pjson(obj)          - 2-space indent by default
%   s = pjson(obj, indent)  - custom indent string (e.g. '    ')
%
% Dependency-free, R2016b+-compatible pretty printer. MATLAB's built-in
% jsonencode only gained 'PrettyPrint' in R2023b, so this shim guards the
% project's R2019b compatibility floor while producing human-readable reports.

if nargin < 2, indent = '  '; end
s = enc(obj, 0, indent);
end

function s = enc(v, level, ind)
pad = repmat(ind, 1, level);
if isstruct(v)
    s = encStruct(v, level, ind);
elseif iscell(v)
    s = encCell(v, level, ind);
elseif isnumeric(v) || islogical(v)
    s = encNumeric(v);
elseif ischar(v) || isstring(v)
    s = ['"' escapeJson(char(v)) '"'];
elseif isempty(v)
    s = 'null';   % matches jsonencode([] char) -> null? use [] for empty numeric
else
    s = jsonencode(v);
end
end

function s = encStruct(v, level, ind)
pad = repmat(ind, 1, level + 1);
clos = repmat(ind, 1, level);
n = numel(v);
if n == 1
    fn = fieldnames(v);
    if isempty(fn)
        s = '{}';
        return;
    end
    lines = cell(1, numel(fn));
    for i = 1:numel(fn)
        k = ['"' escapeJson(fn{i}) '"'];
        valStr = enc(v.(fn{i}), level + 1, ind);
        lines{i} = [pad k ': ' valStr];
    end
    s = ['{' newline strjoin(lines, [',' newline]) newline clos '}'];
else
    s = encArrayElements(arrayfun(@(k) v(k), 1:n, 'UniformOutput', false), level, ind);
end
end

function s = encCell(v, level, ind)
n = numel(v);
if n == 0
    s = '[]';
    return;
end
s = encArrayElements(v, level, ind);
end

function s = encArrayElements(cellv, level, ind)
pad = repmat(ind, 1, level + 1);
clos = repmat(ind, 1, level);
n = numel(cellv);
parts = cell(1, n);
for i = 1:n
    parts{i} = [pad enc(cellv{i}, level + 1, ind)];
end
s = ['[' newline strjoin(parts, [',' newline]) newline clos ']'];
end

function s = encNumeric(v)
if isempty(v)
    s = '[]';
    return;
end
if numel(v) == 1
    if islogical(v)
        if v, s = 'true'; else, s = 'false'; end
    elseif ~isfinite(v)
        s = 'null';
    elseif v == round(v) && abs(v) < 2^53
        s = sprintf('%d', int64(v));
    else
        s = num2str(v);   % ~15 sig digs, clean round-trip for report values
    end
    return;
end
parts = cell(1, numel(v));
for i = 1:numel(v)
    parts{i} = encNumeric(v(i));
end
s = ['[' strjoin(parts, ',') ']'];
end

function s = escapeJson(v)
s = strrep(v, '\', '\\');
s = strrep(s, '"', '\"');
s = strrep(s, sprintf('\n'), '\n');
s = strrep(s, sprintf('\r'), '\r');
s = strrep(s, sprintf('\t'), '\t');
end