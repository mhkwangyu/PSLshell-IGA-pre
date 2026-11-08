#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Migrate PSLshell.m: collapse 48 `global xxx_` into a single global handle
`global state_` (a State handle object), accessed as `state_.xxx_`.

Steps (order matters):
  S1  Replace the `GlobalVariables` function with `initState` that creates and
      returns the State handle, registering it as the single global `state_`.
  S2  Rename the `GlobalVariables()` call in the main PSLshell body to
      `initState();`.
  S3  Replace every remaining `global ...;` declaration line with
      `\tglobal state_`.
  S4  Token-rewrite bare global references `xxx_` -> `state_.xxx_` outside
      comments and string literals, explicitly skipping the tokens `state` and
      `state_` so the new handle name is untouched.
"""
import re

SRC = "PSLshell.m"
OUT = "PSLshell.m"   # in-place (backup already taken at /tmp/PSLshell.m.bak)
lines = open(SRC, encoding="utf-8").read().split("\n")

# ---- locate GlobalVariables span ----
gv_start = gv_end = None
imp_start = None
for i, ln in enumerate(lines):
    if re.search(r'^function\s+GlobalVariables\s*\(', ln):
        gv_start = i
    if re.search(r'^function\s+ImportStressFields\s*\(', ln):
        imp_start = i
        break
assert gv_start is not None and imp_start is not None, "markers not found"
gv_end = imp_start - 1  # 0-based inclusive of last GlobalVariables body line

# ---- S1: replace GlobalVariables with initState ----
init_block = [
    "function initState()",
    "%% Construct the computation-state handle (replaces the former GlobalVariables).",
    "global state_;",
    "\tstate_ = State();",
    "end",
    "",
]
lines[gv_start:gv_end + 1] = init_block

# ---- S2: rename call site ----
# (only one occurrence in main body)
lines = [re.sub(r'\bGlobalVariables\s*\(\s*\)\s*;', 'initState();', ln) for ln in lines]

# ---- S3: replace remaining global declarations ----
def is_global_decl(ln):
    return bool(re.match(r'^\s*global\b', ln))

for i, ln in enumerate(lines):
    if is_global_decl(ln):
        # preserve leading whitespace style
        m = re.match(r'^(\s*)', ln)
        ind = m.group(1) if m else '\t'
        lines[i] = ind + "global state_;"

# ---- S4: token rewrite xxx_ -> state_.xxx_ outside comments/strings ----
# IMPORTANT: MATLAB comment is '%' ONLY outside string literals. Format strings
# like '%s' / '%e %e %e' contain '%' inside quotes and must NOT be treated as
# comments. So we must scan left-to-right tracking string literals: a '%'
# inside a (single- or double-quoted) string is a format char, not a comment.
TOK = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')

def rewrite_identifiers(ln):
    out = []
    i, n = 0, len(ln)
    in_comment = False
    while i < n:
        c = ln[i]
        if in_comment:
            out.append(ln[i:])
            break
        if c == "'" or c == '"':
            # string literal: copy verbatim up to closing (honoring doubled quotes)
            q = c
            j = i + 1
            while j < n:
                if ln[j] == q:
                    if j + 1 < n and ln[j + 1] == q:
                        j += 2
                        continue
                    j += 1  # include closing quote
                    break
                j += 1
            out.append(ln[i:j])
            i = j
            continue
        if c == '%':
            # single '%' outside a string -> comment to end of line
            in_comment = True
            out.append(c)
            i += 1
            continue
        m = TOK.match(ln, i)
        if m:
            tok = m.group(0)
            if tok.endswith('_') and tok not in ('state', 'state_'):
                out.append('state_.' + tok)
            else:
                out.append(tok)
            i = m.end()
            continue
        out.append(c)
        i += 1
    return ''.join(out)

lines = [rewrite_identifiers(ln) for ln in lines]

open(OUT, "w", encoding="utf-8").write("\n".join(lines))
print("migration done.")