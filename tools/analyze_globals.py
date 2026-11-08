#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Analyze PSLshell.m: determine which local functions need a `state` param,
via a fixpoint over the call graph seeded by functions that declare `global`.
Only reads the file and prints analysis. Safe (read-only).
"""
import re, sys, json

path = "PSLshell.m"
lines = open(path, encoding="utf-8").read().split("\n")

# (name, start_line)  — start_line is 1-based
funcs = [
    ("PSLshell", 10),
    ("GlobalVariables", 66),
    ("ImportStressFields", 112),
    ("PreProcessData", 202),
    ("SeedingPSLs", 520),
    ("ShowPSLs", 634),
    ("CompactStreamlines", 1078),
    ("SetupSeeds", 1089),
    ("EmbedTopologicalSkeleton", 1106),
    ("GetDisListOfPointList2Curve", 1170),
    ("HighCurvatureModification", 1178),
    ("AvoidExactLocationAtVertexOrEdge4Robustness", 1202),
    ("CheckWhetherGivenNaturalCoordinatesWithinDomain", 1238),
    ("ComputeLocalFrameAtGivenPosition", 1265),
    ("ComputeNormalsAtGivenPosition", 1289),
    ("ComputePrincipalStressLocalFrame", 1299),
    ("ComputeVonMisesStressLocalFrame", 1325),
    ("ConvertNaturalCoordsAtSharedEdge", 1337),
    ("EdgeProgress", 1351),
    ("NatFromProgress", 1372),
    ("CreatePrincipalStressLine", 1392),
    ("Tracing", 1460),
    ("BidirectionalFeatureProcessing", 1589),
    ("BidirectionalFeatureProcessing_Advanced", 1607),
    ("ComputeIncrementOfNaturalCoordFromIncrementOfLocalCoord", 1639),
    ("CheckSignedDihedralAngle", 1647),
    ("EdgeSituationProcessing", 1659),
    ("RetrievePhyInfoAtUpdatedPt", 1697),
    ("DeShapeFunction", 1722),
    ("DetectIntersectedEdgeInNaturalFrame", 1791),
    ("DistanceMap2PtCloud", 1991),
    ("EvaluateMeshNormals", 2011),
    ("ExpandPSLs2Tubes", 2028),
    ("GetSpheresOfPoints", 2084),
    ("GlobalFrame2Local_Coords", 2105),
    ("GlobalFrame2Local_StressTensor", 2118),
    ("GlobalFrame2Local_Vecs", 2147),
    ("PreparingForTracing", 2160),
    ("PrincipalStressLineStruct", 2217),
    ("SeedSecurityCheck4Robustness", 2232),
    ("TransferToNextElement_StandardSharedEdgeCase", 2325),
    ("DetermineExternalNormalOfGivenEdgeInLocalFrame", 2359),
    ("TransferToNextElement_StandardSharedNodeCase", 2385),
    ("NewtonRhapson_LocatingPosition3D", 2456),
    ("ProjectToTriangle", 2565),
    ("ProjOnSeg", 2583),
    ("ShapeFunction", 2590),
    ("ShowMeshNormals", 2629),
    ("ShowPrincipalStressDirectionsByArrowsGlobally", 2639),
    ("ShowProblemDescription", 2774),
    ("StressTopologyAnalysis", 2815),
    ("ComputeTopologicalSkeletons", 2826),
    ("DegeneratePointStruct", 2925),
    ("LocateDegeneratePoints", 2943),
    ("IdentifyCandidateElements", 3090),
    ("DegenrationMeasure_SignConsistency", 3113),
    ("DegenrationMeasure_BernsteinBoundingQuad", 3121),
    ("NewtonRhapson_LocatingDegPt", 3143),
    ("pslDefaultProfile", 3337),
]

# compute end lines (1-based inclusive)
ends = []
for k in range(len(funcs)):
    s = funcs[k][1]
    if k + 1 < len(funcs):
        e = funcs[k + 1][1] - 1
    else:
        e = len(lines)
    ends.append(e)

names = [f[0] for f in funcs]
start = {f[0]: f[1] for f in funcs}
end = {f[0]: e for f, e in zip(funcs, ends)}

# seed: functions that declare global
seeds = set()
global_pat = re.compile(r'^\s*global\b')
for n, s in funcs:
    for ln in range(s, end[n] + 1):
        if global_pat.match(lines[ln - 1]):
            seeds.add(n)
            break

# call graph: for each function, which local functions it calls
calls = {n: set() for n in names}
for n, s in funcs:
    body = "\n".join(lines[s - 1:end[n]])
    # remove the function definition line(s) to avoid self-match on def line
    for m in names:
        if m == n:
            continue
        # function name used as call: `m(` or `m (` (word boundary)
        if re.search(r'\b' + re.escape(m) + r'\s*\(', body):
            calls[n].add(m)

# fixpoint
need = set(seeds)
changed = True
while changed:
    changed = False
    for n in names:
        if n in need:
            continue
        if calls[n] & need:
            need.add(n)
            changed = True

# report
print("=== SEEDS (declare global) ===")
for s in sorted(seeds):
    print("  ", s)
print()
print("=== NEED state (fixpoint) ===")
for s in sorted(need):
    print("  ", s)
print()
print("=== PURE (no state) ===")
for s in sorted(set(names) - need - {"PSLshell", "GlobalVariables"}):
    print("  ", s)
print()
print("total funcs:", len(funcs), " need-state:", len(need), " seeds:", len(seeds))

# call graph detail for functions that need state
print()
print("=== call edges (caller -> callee, both may matter) ===")
for n in sorted(need):
    cn = sorted(calls[n] & need)
    if cn:
        print(f"  {n} -> {cn}")