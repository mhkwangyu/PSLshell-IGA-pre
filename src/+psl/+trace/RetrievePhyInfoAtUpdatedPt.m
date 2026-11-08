function [iPhyCoord, iLocalFrame, t1, t2, iStressTensor, iVonMisesStress, iPrincipalStress] = RetrievePhyInfoAtUpdatedPt(e0, paraCoord1, e0Type)
	global state_;
	global state_;
	global state_;

	switch e0Type
		case 'T3', iEleNodes = state_.eNodMat_(e0,1:3);
		case 'Q4', iEleNodes = state_.eNodMat_(e0,1:4);
		case 'T6', iEleNodes = state_.eNodMat_(e0,1:6);
		case 'Q8', iEleNodes = state_.eNodMat_(e0,1:8);				
	end
	SF = psl.mesh.ShapeFunction(paraCoord1, e0Type);
	iEleNodeCoords = state_.nodeCoords_(iEleNodes,:);
	iPhyCoord = SF * iEleNodeCoords;
	[iLocalFrame, ~, t1, t2] = psl.mesh.ComputeLocalFrameAtGivenPosition(paraCoord1, iEleNodeCoords, e0Type);
	if state_.approxiInterp_
		iStressTensor = SF * state_.localStressFieldPerEle_{e0};
	else
		iStressTensorGlobal = SF * state_.globalStressFieldPerEle_{e0};
		iStressTensor = psl.stress.GlobalFrame2Local_StressTensor(iStressTensorGlobal, iLocalFrame, 1);
	end
	iVonMisesStress = psl.stress.ComputeVonMisesStressLocalFrame(iStressTensor);
	iPrincipalStress = psl.stress.ComputePrincipalStressLocalFrame(iStressTensor);	
end

