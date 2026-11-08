#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Split PSLshell.m's local functions into src/+psl/+<pkg>/<name>.m packages.

Rules:
  - 3 ROOT functions stay in PSLshell.m: PSLshell, initState, pslDefaultProfile.
  - Every other function becomes src/+psl/+<pkg>/<Name>.m (one file each).
  - Inside each moved function, calls to any OTHER moved function are rewritten
    to the fully-qualified psl.<pkg>.<Name> (required even for same-package
    calls in MATLAB packages).
  - `global state_` stays unchanged (handle is shared across packages).
"""
import re, os

SRC = "PSLshell.m"
ROOT_DIR = os.path.dirname(os.path.abspath(SRC))
PKG = os.path.join(ROOT_DIR, "src", "+psl")

# (name, start_line_1based, package)  —— package 'ROOT' stays in PSLshell.m
FUNCS = [
    ("PSLshell", 10, "ROOT"),
    ("initState", 66, "ROOT"),
    ("ImportStressFields", 75, "io"),
    ("PreProcessData", 165, "mesh"),
    ("SeedingPSLs", 483, "trace"),
    ("ShowPSLs", 597, "vis"),
    ("CompactStreamlines", 1041, "trace"),
    ("SetupSeeds", 1052, "trace"),
    ("EmbedTopologicalSkeleton", 1069, "trace"),
    ("GetDisListOfPointList2Curve", 1133, "trace"),
    ("HighCurvatureModification", 1141, "trace"),
    ("AvoidExactLocationAtVertexOrEdge4Robustness", 1165, "mesh"),
    ("CheckWhetherGivenNaturalCoordinatesWithinDomain", 1201, "mesh"),
    ("ComputeLocalFrameAtGivenPosition", 1228, "mesh"),
    ("ComputeNormalsAtGivenPosition", 1252, "mesh"),
    ("ComputePrincipalStressLocalFrame", 1262, "stress"),
    ("ComputeVonMisesStressLocalFrame", 1288, "stress"),
    ("ConvertNaturalCoordsAtSharedEdge", 1300, "mesh"),
    ("EdgeProgress", 1314, "mesh"),
    ("NatFromProgress", 1335, "mesh"),
    ("CreatePrincipalStressLine", 1355, "trace"),
    ("Tracing", 1423, "trace"),
    ("BidirectionalFeatureProcessing", 1552, "trace"),
    ("BidirectionalFeatureProcessing_Advanced", 1570, "trace"),
    ("ComputeIncrementOfNaturalCoordFromIncrementOfLocalCoord", 1602, "trace"),
    ("CheckSignedDihedralAngle", 1610, "trace"),
    ("EdgeSituationProcessing", 1622, "trace"),
    ("RetrievePhyInfoAtUpdatedPt", 1660, "trace"),
    ("DeShapeFunction", 1685, "mesh"),
    ("DetectIntersectedEdgeInNaturalFrame", 1754, "mesh"),
    ("DistanceMap2PtCloud", 1954, "mesh"),
    ("EvaluateMeshNormals", 1974, "mesh"),
    ("ExpandPSLs2Tubes", 1991, "vis"),
    ("GetSpheresOfPoints", 2047, "vis"),
    ("GlobalFrame2Local_Coords", 2068, "stress"),
    ("GlobalFrame2Local_StressTensor", 2081, "stress"),
    ("GlobalFrame2Local_Vecs", 2110, "stress"),
    ("PreparingForTracing", 2123, "trace"),
    ("PrincipalStressLineStruct", 2180, "trace"),
    ("SeedSecurityCheck4Robustness", 2195, "trace"),
    ("TransferToNextElement_StandardSharedEdgeCase", 2288, "mesh"),
    ("DetermineExternalNormalOfGivenEdgeInLocalFrame", 2322, "mesh"),
    ("TransferToNextElement_StandardSharedNodeCase", 2348, "mesh"),
    ("NewtonRhapson_LocatingPosition3D", 2419, "mesh"),
    ("ProjectToTriangle", 2528, "mesh"),
    ("ProjOnSeg", 2546, "mesh"),
    ("ShapeFunction", 2553, "mesh"),
    ("ShowMeshNormals", 2592, "vis"),
    ("ShowPrincipalStressDirectionsByArrowsGlobally", 2602, "vis"),
    ("ShowProblemDescription", 2737, "vis"),
    ("StressTopologyAnalysis", 2778, "topology"),
    ("ComputeTopologicalSkeletons", 2789, "topology"),
    ("DegeneratePointStruct", 2888, "topology"),
    ("LocateDegeneratePoints", 2906, "topology"),
    ("IdentifyCandidateElements", 3053, "topology"),
    ("DegenrationMeasure_SignConsistency", 3076, "topology"),
    ("DegenrationMeasure_BernsteinBoundingQuad", 3084, "topology"),
    ("NewtonRhapson_LocatingDegPt", 3106, "topology"),
    ("pslDefaultProfile", 3300, "ROOT"),
]

lines = open(SRC, encoding="utf-8").read().split("\n")

# name -> (start, end, pkg)
info = {}
for k, (name, s, pkg) in enumerate(FUNCS):
    e = FUNCS[k + 1][1] - 1 if k + 1 < len(FUNCS) else len(lines)
    info[name] = (s, e, pkg)

# moved (non-ROOT) name -> pkg
name2pkg = {n: info[n][2] for n in info if info[n][2] != "ROOT"}

TOK = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')

def rewrite_body(body_lines, self_name):
    """Rewrite cross-calls in a list of lines; skip the function's own name."""
    out = []
    for ln in body_lines:
        res = []
        i, n = 0, len(ln)
        in_comment = False
        while i < n:
            c = ln[i]
            if in_comment:
                res.append(ln[i:])
                break
            if c == "'" or c == '"':
                q = c
                j = i + 1
                while j < n:
                    if ln[j] == q:
                        if j + 1 < n and ln[j + 1] == q:
                            j += 2
                            continue
                        j += 1
                        break
                    j += 1
                res.append(ln[i:j])
                i = j
                continue
            if c == '%':
                in_comment = True
                res.append(c)
                i += 1
                continue
            m = TOK.match(ln, i)
            if m:
                tok = m.group(0)
                if tok in name2pkg and tok != self_name:
                    res.append('psl.%s.%s' % (name2pkg[tok], tok))
                else:
                    res.append(tok)
                i = m.end()
                continue
            res.append(c)
            i += 1
        out.append(''.join(res))
    return out

def dry_run():
    print("=== 拆分计划（name -> 文件/保留）===")
    for name, (s, e, pkg) in info.items():
        if pkg == "ROOT":
            print(f"  保留  {name:50} L{s}-{e}  (PSLshell.m)")
        else:
            path = f"src/+psl/+{pkg}/{name}.m"
            print(f"  迁移  {name:50} L{s}-{e}  -> {path}")
    print("总计:", len(FUNCS), "个；迁移", sum(1 for v in info.values() if v[2] != 'ROOT'), "个；保留", sum(1 for v in info.values() if v[2] == 'ROOT'), "个")

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "dry":
        dry_run()
        sys.exit(0)

    # 1) write each moved function file
    for name in name2pkg:
        s, e, pkg = info[name]
        body = lines[s - 1:e]
        newbody = rewrite_body(body, name)
        pdir = os.path.join(PKG, "+" + pkg)
        os.makedirs(pdir, exist_ok=True)
        fpath = os.path.join(pdir, name + ".m")
        with open(fpath, "w", encoding="utf-8") as f:
            f.write("\n".join(newbody) + "\n")
        print("wrote", fpath)

    # 2) rebuild PSLshell.m: keep header comment + 3 ROOT functions
    header = lines[0:9]  # L1-8 comment block + blank line 9
    # PSLshell function body (ROOT), rewrite its cross-calls to psl.*
    ps_s, ps_e, _ = info["PSLshell"]
    init_s, init_e, _ = info["initState"]
    def_s, def_e, _ = info["pslDefaultProfile"]

    psl_body = rewrite_body(lines[ps_s - 1:ps_e], "PSLshell")
    init_body = lines[init_s - 1:init_e]
    def_body = lines[def_s - 1:def_e]

    new_main = []
    new_main.extend(header)
    new_main.append("")
    new_main.extend(psl_body)
    new_main.append("")
    new_main.extend(init_body)
    new_main.append("")
    new_main.extend(def_body)
    new_main.append("")

    with open(SRC, "w", encoding="utf-8") as f:
        f.write("\n".join(new_main))

    print("rebuilt PSLshell.m (", len(new_main), "lines )")
    print("done.")