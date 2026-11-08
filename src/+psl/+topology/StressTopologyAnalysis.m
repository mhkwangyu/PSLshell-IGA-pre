function StressTopologyAnalysis()
	%%1. Identify Candidate Elements for Topology Analysis
	psl.topology.IdentifyCandidateElements();
	
	%%2. Locate Degenerate Points	
	psl.topology.LocateDegeneratePoints();	
	
	%%3. Compute Topological Skeleton
	psl.topology.ComputeTopologicalSkeletons();
end

