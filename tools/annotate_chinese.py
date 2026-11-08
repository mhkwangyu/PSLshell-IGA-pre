#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""给 src/+psl 各函数注入中文头注释（依据 paper_reading 论文精读 §11 函数对照表）。

只做"在 function 签名行之后插入注释块"，不改任何可执行代码，保证回归等价。
"""

import os, re

SRC = "src/+psl"

# 每个函数：文件相对路径 -> 头注释块（含论文章节引用）
# 注释格式：紧跟 function 行之后，用 %% 开头的多行块。
ANNOT = {

"+trace/ComputeIncrementOfNaturalCoordFromIncrementOfLocalCoord.m":
"""%% 【论文 §3.2, Eq.15-16】自然坐标增量求解 —— 全文"心脏"一步。
%% 把"该走多远"（局部系位置增量 localCoordIncrement 有物理意义）翻译成
%% 自然坐标增量 Δ(ξ,η)。组装面 Jacobian J = [e1·t1 e1·t2; e2·t1 e2·t2]，
%% 求 Δ(ξ,η) = J^{-1} · Δx。关键收益：新点始终定义在自然坐标里，
%% 判断是否越界退化为"与标准等参单元比大小"，无需 Newton-Raphson 反解位置。
""",

"+mesh/ComputeLocalFrameAtGivenPosition.m":
"""%% 【论文 §2.1, Eq.2-6】在任一点 (ξ,η) 构造单元局部正交系 R = [e1 e2 e3]。
%% t1=∂P/∂ξ, t2=∂P/∂η 为切向量；法向 e3=t1×t2/|t1×t2|；
%% 用参考向量 r（默认 [1,0,0]，与法向近平行时退回 [0,0,1]）投影到切平面得 e1，
%% 右手法则 e2=e3×e1。离散化关键：r 的约定决定了局部主方向角，读外部应力须一致。
""",

"+mesh/ShapeFunction.m":
"""%% 【论文 §2, Eq.1】等参形函数 N(ξ,η)。支持 T3(线性)/Q4(双线性)/T6(二次)/Q8(双二次)。
%% 等参映射 P(ξ,η)=Σ N_i P_i 是"直接在自然坐标里推进"这一核心思想的基础。
""",

"+mesh/DeShapeFunction.m":
"""%% 【论文 §2.1】形函数对自然坐标的一阶导数 dN/dξ、dN/dη。
%% 用于求切向量 t1,t2（抛物线/双二次单元的切平面随 (ξ,η) 变化）。
""",

"+mesh/ComputeNormalsAtGivenPosition.m":
"""%% 【论文 §2.1】在任一点求法向与两个切向量（供法向可视化/局部系构造使用）。
""",

"+mesh/DistanceMap2PtCloud.m":
"""%% 【论文 §5】种子点到已有轨迹的距离图（合并阈值判定用）。
%% 支持欧氏(Euclidean)与测地(Geodesic)两种度量。论文强调：薄壁件必须用测地距离，
%% 否则欧氏距离会把上下表面"贴"在一起导致种子被错误合并（详见机翼算例图14）。
%% 注意：欧氏分支为 O(n×m) 稠密矩阵，第四期性能优化重点。
""",

"+mesh/DetectIntersectedEdgeInNaturalFrame.m":
"""%% 【论文 §3.2, 图3】求线段 s_n→s_{n+1} 与当前等参单元顶点边的交点（跨单元四步的第1步）。
""",

"+mesh/ConvertNaturalCoordsAtSharedEdge.m":
"""%% 【论文 §3.2, 图3】沿共享边搬运自然坐标：把某单元边上一点按相对位置映射到相邻单元对应边。
""",

"+mesh/EdgeProgress.m":
"""%% 【论文 §3.2】自然坐标中沿某条边按参数 t 前进（跨单元搬运的辅助工具）。
""",

"+mesh/NatFromProgress.m":
"""%% 【论文 §3.2】由边参数 t 反解出该边上的自然坐标 (ξ,η)（EdgeProgress 的逆）。
""",

"+mesh/CheckWhetherGivenNaturalCoordinatesWithinDomain.m":
"""%% 【论文 §2, Eq.16 收益】判断自然坐标是否落在标准等参单元内：
%% 三角形 (0,0)-(1,0)-(0,1)，四边形 [-1,1]^2。纯几何判断，是"定位变廉价"的关键。
""",

"+mesh/AvoidExactLocationAtVertexOrEdge4Robustness.m":
"""%% 【论文 §3.2】把恰好落在顶点/边上的自然坐标微调入内部，避免跨单元判定时的退化歧义（鲁棒性补丁）。
""",

"+mesh/PreProcessData.m":
"""%% 【论文 §2, §3】预处理：建单元质心、节点-单元邻接表(nodStruct)、单元-边-邻接(eleStruct)、
%% 剖分三角化、单元特征尺寸/曲率标定、以及 vis 用的 silhouette 等派生结构。
%% 这些连接表是 §3.2"沿共享边搬运"的高效实现基础。
""",

"+mesh/EvaluateMeshNormals.m":
"""%% 【论文 §2.1】批量求每个单元法向（供"检查网格法向外翻"的入口分支使用）。
""",

"+mesh/TransferToNextElement_StandardSharedEdgeCase.m":
"""%% 【论文 §3.2, 图3】跨单元搬运：标准"共享边"情形——沿共享边把点从 e_n 搬到相邻单元 e_{n+1}。
""",

"+mesh/TransferToNextElement_StandardSharedNodeCase.m":
"""%% 【论文 §3.2】跨单元搬运：点落在共享"节点"（非边中点）时的特殊情形处理。
""",

"+mesh/DetermineExternalNormalOfGivenEdgeInLocalFrame.m":
"""%% 【论文 §3.2】求给定边在局部系中的外法向（跨单元方向判定辅助）。
""",

"+mesh/NewtonRhapson_LocatingPosition3D.m":
"""%% 【论文 §3.1】阻尼 Newton 求目标应力状态对应的自然坐标（三维定位的通用求根器，
%% 用于退化点搜索与特定位置反解；与"追踪时无需反解"互补）。
""",

"+mesh/ProjectToTriangle.m":
"""%% 【论文 附录】把任意点正交投影到三角形（求根/定位辅助）。
""",

"+mesh/ProjOnSeg.m":
"""%% 【论文 附录】把点正交投影到线段（ProjectToTriangle 的子工具）。
""",

"+stress/ComputePrincipalStressLocalFrame.m":
"""%% 【论文 §2.3, Eq.10 之后】面内/三维应力张量的主应力与主方向特征分解(eig)。
%% 3 列输入=局部系面内应力[σxx,σyy,σxy]；6 列输入=全局系对称张量 Voigt 形式。
""",

"+stress/ComputeVonMisesStressLocalFrame.m":
"""%% 【论文 图1】von Mises 等效应力（供着色可视化）。
""",

"+stress/GlobalFrame2Local_Coords.m":
"""%% 【论文 §2.2, Eq.7】全局坐标 → 局部系坐标变换。
""",

"+stress/GlobalFrame2Local_StressTensor.m":
"""%% 【论文 §2.2, Eq.9-10】全局系应力张量 → 局部系（面内）应力。opt 控制是否做三维嵌入。
""",

"+stress/GlobalFrame2Local_Vecs.m":
"""%% 【论文 §2.2, Eq.8】全局向量 → 局部系向量（方向对比都在全局系做，见 Eq.17）。
""",

"+trace/SeedingPSLs.m":
"""%% 【论文 §5, 图10】拓扑感知播种主循环（ref. 3D-TSV 价态机制）。
%% 每个种子带二值价态 [major被主PSL穿过, minor被次PSL穿过]，"边画边记账"：
%% 一条 PSL 生成后合并阈值内种子、置对应价态=1；骨架优先嵌入，再铺满全域。
%% 间距阈值 = D_min / PSLsDensityCtrl（ω 越大越密）。
""",

"+trace/SetupSeeds.m":
"""%% 【论文 §5】初始化种子点：按 seedSparsityCtrl 稀疏度取单元中心作为种子。
""",

"+trace/EmbedTopologicalSkeleton.m":
"""%% 【论文 §4.2, §5】把拓扑骨架并入主/次 PSL 池并同步种子价态（骨架优先的落地）。
""",

"+trace/HighCurvatureModification.m":
"""%% 【论文 §5】高曲率区的种子价态修正：避免相邻薄壁/折边处种子被遗漏。
""",

"+trace/GetDisListOfPointList2Curve.m":
"""%% 【论文 §5】种子点集合到某条轨迹的最近距离（供合并判定）。
""",

"+trace/CreatePrincipalStressLine.m":
"""%% 【论文 §3.3, 图5】单条 PSL 的总控：准备初始状态 → 沿正/负两方向分别 Tracing → 拼接。
%% psDir 区分主(MAJOR)/次(MINOR)；可选 varargin 传入退化点处的预设骨架方向。
""",

"+trace/Tracing.m":
"""%% 【论文 §3, 图5】单个方向的积分主循环（Euler/RK2）。
%% 步长 δ_e = Ce/(scalingStepSize*curvatureScaling) 自适应（Eq.23 思想）；
%% 越界则走 EdgeSituationProcessing 搬运，否则方向正则后继续；三个终止出口：
%% 到达边界 / 方向突变(>permittedMaxAdjacentTangentAngleDeviation) / 步数耗尽。
""",

"+trace/PreparingForTracing.m":
"""%% 【论文 §3.3】追踪前准备：由种子算初始物理坐标/局部系/应力/主方向，并做边界安全兜底。
""",

"+trace/RetrievePhyInfoAtUpdatedPt.m":
"""%% 【论文 §2.3, Eq.10】更新点处的定向信息检索：物理坐标、局部系、应力张量、
%% von Mises、主应力/主方向。核心是一致应力插值（节点应力→全局系插值→投影回局部系）。
""",

"+trace/BidirectionalFeatureProcessing.m":
"""%% 【论文 §3.3, Eq.17】方向正则（平滑情形）：主方向是"轴"不是"箭头"，
%% 在两个候选 ±v 里选与上一步夹角更小者；超过阈值(默认45°)判终止。
""",

"+trace/BidirectionalFeatureProcessing_Advanced.m":
"""%% 【论文 §3.4, Eq.17-21】方向正则（跨单元/折痕情形）：含 30° 近共面快路径(跳过旋转)
%% 与 Rodrigues 旋转 W(h,α)=I+sinα·H+(1-cosα)H² 把上一单元方向"掰"到当前切平面再比较。
""",

"+trace/CheckSignedDihedralAngle.m":
"""%% 【论文 §3.4, Eq.18】有符号二面角 α=atan2(h·(n1×n2), n1·n2)：凸脊>0，凹谷<0。
""",

"+trace/EdgeSituationProcessing.m":
"""%% 【论文 §3.2, 图3】越界情形统一处理：找交点→映射边→搬运到相邻单元/判定达边界。
""",

"+trace/SeedSecurityCheck4Robustness.m":
"""%% 【论文 §3.2】种子鲁棒性检查：把种子归一化到合法单元内、法向一致、边点微调。
""",

"+trace/CompactStreamlines.m":
"""%% 【论文 §5】抽稀：过滤积分点数过少(<=truncatedThreshold)的碎短轨迹。
""",

"+trace/PrincipalStressLineStruct.m":
"""%% 【PSL 数据结构】单条主应力线的字段容器（坐标/单元/参数/局部系/应力列表）。
""",

"+topology/StressTopologyAnalysis.m":
"""%% 【论文 §4, 图9】应力拓扑分析总管线：预选候选单元 → 定位退化点 → 计算拓扑骨架。
""",

"+topology/IdentifyCandidateElements.m":
"""%% 【论文 §4.3, Eq.35-39】候选单元预筛：符号一致性检查 + Bernstein-Bézier 区间界，
%% 严格排除不可能含退化点的单元（对任意阶次成立，大幅缩小搜索范围）。
""",

"+topology/LocateDegeneratePoints.m":
"""%% 【论文 §4.1, Eq.24】定位退化点：偏应力向量 g=(f1,f2)=(½(σxx-σyy), σxy) 的零点
%% 即两主应力相等（莫尔圆半径=0）处。T6/Q8 细分子域各至多一根，共享边去重。
""",

"+topology/NewtonRhapson_LocatingDegPt.m":
"""%% 【论文 §4.1】阻尼 Newton 求偏应力向量零点（退化点的精确位置）。
""",

"+topology/DegenrationMeasure_SignConsistency.m":
"""%% 【论文 §4.3】退化点预筛判据1：节点上 f1(或 f2) 符号一致则单元必无退化点（T3/Q4/T6 有效）。
""",

"+topology/DegenrationMeasure_BernsteinBoundingQuad.m":
"""%% 【论文 §4.3, Eq.35-39, 附录A】退化点预筛判据2：Bernstein-Bézier 凸包区间界，
%% 系数经 C·S·C^T 变换，[minB,maxB] 严格界定函数范围，可严格排除（对 Q8 亦有效）。
""",

"+topology/ComputeTopologicalSkeletons.m":
"""%% 【论文 §4.2, Eq.27-31】计算拓扑骨架：对每个退化点求偏应力场一阶导矩阵 M，
%% delta=det(M) 判 trisector(<0)/wedge(>0)；实根三次方程 d·t³+(c+2b)t²+(2a-d)t-c=0
%% 给出骨架分支方向，再从退化点出发沿各方向 Tracing 生成骨架 PSL。
""",

"+topology/DegeneratePointStruct.m":
"""%% 【退化点数据结构】退化点字段容器（单元/参数坐标/物理坐标/delta/骨架等）。
""",

"+vis/ShowPSLs.m":
"""%% 【论文 图1 及结果渲染】PSL 可视化主函数：网格 silhouette + 主/次 PSL 管状渲染 +
%% 退化点球 + 拓扑骨架，支持应力云图着色或干净迹线两种风格。
""",

"+vis/ExpandPSLs2Tubes.m":
"""%% 【论文 图13e】把 PSL 折线扩展为管状曲面（tube），显式着色。
""",

"+vis/GetSpheresOfPoints.m":
"""%% 【论文 图7/9】把点集扩展为球（退化点可视化）。
""",

"+vis/ShowProblemDescription.m":
"""%% 【结果可视化】显示算例问题描述（网格 + 边界条件）。
""",

"+vis/ShowMeshNormals.m":
"""%% 【入口 else 分支】显示网格法向（检查法向外翻）。
""",

"+vis/ShowPrincipalStressDirectionsByArrowsGlobally.m":
"""%% 【结果可视化】用箭头显示主应力方向场（辅助自检）。
""",

"+io/ImportStressFields.m":
"""%% 【论文 统一文件接口】解析 TSV 文件：网格(顶点/单元)+应力(节点局部或全局)+边界条件
%% (NodeForces/FixedNodes)+局部系参考向量，兼容标准 FEM 输出（ABAQUS 等）。
""",
}

def inject(path, block):
    with open(path, encoding="utf-8") as f:
        lines = f.read().split("\n")
    out = []
    injected = False
    i = 0
    # 找到 function 签名完整结束的行（跨续行 ... 处理）
    sig_start = None
    while i < len(lines) and not injected:
        ln = lines[i]
        out.append(ln)
        if sig_start is None:
            if re.match(r'^\s*function\b', ln):
                sig_start = i
        # 签名尚未结束：当前行以 ... 结尾则续行，否则签名结束
        if sig_start is not None:
            stripped = ln.rstrip()
            if stripped.endswith('...'):
                i += 1
                continue
            else:
                # 签名结束，插入注释块
                for bl in block.rstrip("\n").split("\n"):
                    out.append(bl)
                injected = True
        i += 1
    # 追加剩余行
    while i < len(lines):
        out.append(lines[i])
        i += 1
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out))

def main(mode="dry"):
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", SRC)
    root = os.path.normpath(root)
    n = 0
    for rel, block in ANNOT.items():
        path = os.path.join(root, rel.replace("/", os.sep))
        if not os.path.exists(path):
            print("!! 缺失文件:", path)
            continue
        if mode == "dry":
            print("  [DRY] 将注释:", rel)
        else:
            inject(path, block)
            print("  已注释:", rel)
        n += 1
    print(f"\n共处理 {n} 个函数（模式={mode}）")

if __name__ == "__main__":
    import sys
    main(sys.argv[1] if len(sys.argv) > 1 else "dry")