function faceNormals = EvaluateMeshNormals()
	global state_;
	faceNormals = zeros(state_.numEles_,3);
	for ii=1:state_.numEles_
		iEleType = state_.meshTypeMap_(ii);
		switch iEleType
			case {'T3', 'T6'}
				iEleCoords = state_.nodeCoords_(state_.eNodMat_(ii,1:3),:);
				[R, origin, t1, t2] = psl.mesh.ComputeLocalFrameAtGivenPosition([1 1]/3, iEleCoords, 'T3');
			case {'Q4', 'Q8'}
				iEleCoords = state_.nodeCoords_(state_.eNodMat_(ii,1:4),:);
				[R, origin, t1, t2] = psl.mesh.ComputeLocalFrameAtGivenPosition([0 0], iEleCoords, 'Q4');
		end
		faceNormals(ii,:) = R(:,3)';
	end	
end

