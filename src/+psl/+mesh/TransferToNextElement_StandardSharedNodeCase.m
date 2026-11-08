function [e0out, paraCoord0out, localFrame0out, t1out, t2out, v0out] = ...
	TransferToNextElement_StandardSharedNodeCase(nodeID, e0in, e0Para, localFrame0in, t1in, t2in, v0in)
	global state_;
	global state_;
	global state_;
	global state_;
	global state_;
	
	e0out = e0in;
	paraCoord0out = e0Para;
	localFrame0out = localFrame0in;
	t1out = t1in; 
	t2out = t2in;
	v0out = v0in;
	
	v0inGlobal = psl.stress.GlobalFrame2Local_Vecs(v0in, localFrame0in, 0);
	tarNodeGlobal = state_.eNodMat_(e0in, nodeID);
	tarNodeCoord = state_.nodeCoords_(tarNodeGlobal,:);
	adjElesSharingThisNode = state_.nodStruct_(tarNodeGlobal).adjacentEles;
	numAdjEles = numel(adjElesSharingThisNode);
	refSize = vecnorm(tarNodeCoord-state_.eleCentroids_,2,2)/4;
	
	inside = false;
	for ii=1:numAdjEles
		iEle = adjElesSharingThisNode(ii);
		iEleType = state_.meshTypeMap_(iEle);
		iPerturbationPos = tarNodeCoord + v0inGlobal*refSize(ii);
		switch iEleType
			case 'T3'
				iEleNodes = state_.eNodMat_(iEle, 1:3);
			case 'Q4'
				iEleNodes = state_.eNodMat_(iEle, 1:4);
			case 'T6'
				iEleNodes = state_.eNodMat_(iEle, 1:6);
			case 'Q8'
				iEleNodes = state_.eNodMat_(iEle, 1:8);
		end
		iEleNodeCoordsPhy = state_.nodeCoords_(iEleNodes,:);
		[~, inside] = psl.mesh.NewtonRhapson_LocatingPosition3D(iEleNodeCoordsPhy, iPerturbationPos, iEleType);
		if inside
			e0out = iEle;
			jNodeLocal = find(0==(tarNodeGlobal-iEleNodes));
			switch iEleType
				case {'T3','T6'}
					switch jNodeLocal
						case 1
							paraCoord0out = [0 0];
						case 2
							paraCoord0out = [1 0];
						case 3
							paraCoord0out = [0 1];
					end
				case {'Q4','Q8'}
					switch jNodeLocal
						case 1
							paraCoord0out = [-1 -1];
						case 2
							paraCoord0out = [1 -1];
						case 3
							paraCoord0out = [1 1];
						case 4
							paraCoord0out = [-1 1];
					end				
			end
			[localFrame0out, origin, t1out, t2out] = psl.mesh.ComputeLocalFrameAtGivenPosition(paraCoord0out, iEleNodeCoordsPhy, iEleType);
			v0out = psl.stress.GlobalFrame2Local_Vecs(v0inGlobal, localFrame0out, 1);
			return
		end			
	end
end	

