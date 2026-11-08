function eNormal = DetermineExternalNormalOfGivenEdgeInLocalFrame(e0, edgeID)
%% 【论文 §3.2】求给定边在局部系中的外法向（跨单元方向判定辅助）。
	global state_;
	global state_;
	global state_;
	global state_;
	iEleType = state_.meshTypeMap_(e0);
	vtxCoordsGlobal = state_.eleStruct_(e0).vtxEdgesGlobal(edgeID,:);
	if strcmp(iEleType, 'T3') || strcmp(iEleType, 'T6')
		iEleCoords = state_.nodeCoords_(state_.eNodMat_(e0,1:3),:);
		[R, origin, ~, ~] = psl.mesh.ComputeLocalFrameAtGivenPosition([1 1]/3, iEleCoords, 'T3');
	elseif strcmp(iEleType, 'Q4') || strcmp(iEleType, 'Q8')
		iEleCoords = state_.nodeCoords_(state_.eNodMat_(e0,1:4),:);
		[R, origin, ~, ~] = psl.mesh.ComputeLocalFrameAtGivenPosition([0 0], iEleCoords, 'Q4');
	end
	vtxCoordsLocal = psl.stress.GlobalFrame2Local_Coords(state_.nodeCoords_(vtxCoordsGlobal,:), R, origin, 1);
	edgeVecLocal = vtxCoordsLocal(2,:) - vtxCoordsLocal(1,:); edgeVecLocal = edgeVecLocal / norm(edgeVecLocal);
	normVecRaw = [-edgeVecLocal(2) edgeVecLocal(1)];
	refVec = sum(edgeVecLocal,1)/2; refVec = refVec/norm(refVec);
	devAng = acos(refVec*normVecRaw');
	if devAng < pi/2
		eNormal = normVecRaw;
	else
		eNormal = -normVecRaw;
	end
end

