function disT = DistanceMap2PtCloud(srcPoints, tarCurve)
%% 【论文 §5】种子点到已有轨迹的距离图（合并阈值判定用）。
%% 支持欧氏(Euclidean)与测地(Geodesic)两种度量。论文强调：薄壁件必须用测地距离，
%% 否则欧氏距离会把上下表面"贴"在一起导致种子被错误合并（详见机翼算例图14）。
%% 注意：欧氏分支为 O(n×m) 稠密矩阵，第四期性能优化重点。
	global state_;
	global state_;
	switch state_.distanceMetric_
		case 'Euclidean'
			disT = (tarCurve(:,1) - srcPoints(:,1)').^2;
			disT = disT + (tarCurve(:,2) - srcPoints(:,2)').^2;
			disT = disT + (tarCurve(:,3) - srcPoints(:,3)').^2;
			disT = sqrt(disT);
		case 'Geodesic'
			idtarCurve = nearestNeighbor(state_.triangularizedMesh_, tarCurve);
			idsrcPoints = nearestNeighbor(state_.triangularizedMesh_, srcPoints);	
			[tarCurve_campact, ~, tarCurve_recoverMap] = unique(idtarCurve);
			[srcPoints_campact, ~, srcPoints_recoverMap] = unique(idsrcPoints);
			disT = distances(state_.triangularizedMeshGraph_, tarCurve_campact, srcPoints_campact);
			disT = disT(tarCurve_recoverMap,:);
			disT = disT(:,srcPoints_recoverMap);
	end
end

