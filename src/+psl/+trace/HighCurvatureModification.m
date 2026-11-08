function modifiedValences = HighCurvatureModification(spps2BeMerged, psDir)
%% 【论文 §5】高曲率区的种子价态修正：避免相邻薄壁/折边处种子被遗漏。
	global state_;
	global state_;
	global state_;
	global state_;
	global state_;

	tarCurve = [];
	switch psDir
		case 'MAJOR'
			if isempty(state_.majorCoordList_), modifiedValences = []; return; end
			tarCurve = state_.majorCoordList_;
            spps2BeMerged = spps2BeMerged(0==state_.seedPointsValence_(spps2BeMerged,1));
		case 'MINOR'
			if isempty(state_.minorCoordList_), modifiedValences = []; return; end
			tarCurve = state_.minorCoordList_;
            spps2BeMerged = spps2BeMerged(0==state_.seedPointsValence_(spps2BeMerged,2));
	end
	srcPoints = state_.seedPointsRef_(spps2BeMerged,end-2:end);
	disT = psl.mesh.DistanceMap2PtCloud(srcPoints, tarCurve);	
	minVal = min(disT, [], 1);
	modifiedValences = spps2BeMerged(find(minVal<state_.mergingThreshold_));
end

