# PSLshell

<p align="center">
  <img src="figures/PSLs_demo.png" width="700"/>
</p>

Topology-aware principal stress line tracing on shell structures.

**PSLshell** is a MATLAB implementation for tracing and visualizing principal stress lines (PSLs) on shell structures.

It accompanies the paper:

> Junpeng Wang, Yingjian Liu, Jun Wu, and Rüdiger Westermann  
> *Topology-aware Stress Analysis in Shell Structures*  
> Computer Methods in Applied Mechanics and Engineering, 2026

---

## Overview

PSLshell performs topology-aware stress analysis on shell meshes and extracts:

- Major and minor principal stress lines (PSLs)
- Degenerate points of the stress field
- Topological skeleton structures

The method operates directly on FEM stress fields and supports mixed shell meshes.

---

## Features

- Principal stress line tracing on shell surfaces  
- Supports shell elements:
  - T3 / Q4 / T6 / Q8  
- Works with triangular, quadrilateral, and hybrid meshes  
- Handles node-wise or element-wise stress data  
- Topology-aware PSL seeding and distribution control  
- Detection of degenerate points and skeleton extraction  
- Lightweight `.TSV` interface for FEM data  
- Modular package layout under `src/+psl` (`+io`/`+mesh`/`+stress`/`+trace`/`+topology`/`+vis`)  

---

## Requirements

- **MATLAB R2019b or later**（无第三方工具箱依赖；JSON 用内置 `jsondecode`/`jsonencode`，出图用 `print`）
- 无 Octave 支持

---

## 目录结构

```
PSLshell/
├── PSLshell.m            # 入口函数（自动 addpath('src')）
├── State.m               # 计算状态 handle（原 48 个 global 收敛于此）
├── src/+psl/             # 核心库（包）
│   ├── +io/              #   ImportStressFields（TSV 解析）
│   ├── +mesh/            #   ShapeFunction/PreProcessData/邻接/局部系
│   ├── +stress/          #   主应力/局部框架变换
│   ├── +trace/           #   Tracing/Seeding/PSL 生成
│   ├── +topology/        #   退化点/拓扑骨架
│   └── +vis/             #   ShowPSLs/可视化
├── baseline/             # 回归基线（19 案例黄金快照 + 迹线图）
├── tests/                # 回归测试（regression_test.m + pjson.m）
├── data/                 # 19 个算例 TSV
└── paper_reading/        # 论文精读文稿（读代码参考）
```

---

## Input Data

PSLshell reads stress fields from a `.TSV` file, which contains:

- Mesh vertices  
- Element connectivity  
- Boundary condition Info (optional)
- Stress tensor components  

The stress tensor can be defined in:

- Local shell coordinates, or  
- Global Cartesian coordinates  

---

## Quick Start

Run in MATLAB:

```matlab
PSLshell
```

## Key Parameters

- **PSLsDensityCtrl**  
  Controls PSL density (larger → denser lines)

- **PSLtypeCtrl = [major, minor]**  
  0 = generate, 1 = skip

- **topologyAware**  
  Enable topology-aware PSL tracing

- **distanceMetric**  
  'Euclidean' or 'Geodesic'

- **seedSparsityCtrl**  
  Controls seed sampling density

- **maxIts**  
  Maximum integration steps per PSL
  
## Output

PSLshell generates:

- Major PSLs  
- Minor PSLs  
- Degenerate points  
- Topological skeletons  

## 回归测试（Regression Test）

本仓库内置回归测试与黄金基线，用于验证重构后的数值等价性：

```matlab
addpath('baseline'); addpath('tests');
regression_test()                              % 全部 19 案例
regression_test('cylinder_Q4')                 % 单案例
regression_test({'cylinder_Q4','plate_bottom'})% 子集
```

报告产出到 `report/latest/`（`index.html` 含每案例迹线图 + 状态 + 误差，`summary.json` 多行缩进，`regression.xml` 供 CI）。回归全过程在 `matlab -batch` 下运行，`-batch` 场景末尾自动 `exit(0)` 干净退出。

> 说明：全量 19 案例回归耗时较长（TPMS 系最重）；日常开发建议先跑快档（cylinder/plate/wind_blade 共 10 案例）。

## Citation
```bibtex
If you use this code, please cite:
@article{wang2026topology,
  title={Topology-aware stress analysis in shell structures},
  author={Wang, Junpeng and Liu, Yingjian and Wu, Jun and Westermann, R{\"u}diger},
  journal={Computer Methods in Applied Mechanics and Engineering},
  volume={452},
  pages={118770},
  year={2026},
  publisher={Elsevier}
}
```

## Author
Junpeng Wang  
Technical University of Munich  
junpeng.wang@tum.de