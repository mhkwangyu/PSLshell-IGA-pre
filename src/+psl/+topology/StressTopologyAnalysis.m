function StressTopologyAnalysis()
%% 【论文 §4, 图9】应力拓扑分析总管线：预选候选单元 → 定位退化点 → 计算拓扑骨架。
	%%1. Identify Candidate Elements for Topology Analysis
	psl.topology.IdentifyCandidateElements();
	
	%%2. Locate Degenerate Points	
	psl.topology.LocateDegeneratePoints();	
	
	%%3. Compute Topological Skeleton
	psl.topology.ComputeTopologicalSkeletons();
end

