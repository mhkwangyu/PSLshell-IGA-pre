function disT = DistanceMap2PtCloud(srcPoints, tarCurve)
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

