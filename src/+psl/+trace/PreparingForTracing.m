function [seed0, phyCoord, localCoord, localFrame, t1, t2, localStressTensor, localPrincipalStress, localVonMisesStress, opt] = PreparingForTracing(startPoint)
	global state_;
	global state_;
	global state_;
	
	ele = startPoint(1);
	paras = startPoint(2:3); %% Natural Coordinates
	
	phyCoord = NaN; 
	localCoord = NaN;
	localFrame = NaN;
	t1 = NaN;
	t2 = NaN;
	localStressTensor = NaN; 
	localPrincipalStress = NaN; 
	localVonMisesStress = NaN;
	if state_.voidEleMap_(ele), opt = false; return; end
	
	eleType = state_.meshTypeMap_(ele);
	switch eleType
		case 'T3'
			eleOrder = 1;
			nodeListPerEle = 1:3;			
		case 'Q4'
			eleOrder = 1;
			nodeListPerEle = 1:4;
		case 'T6'
			eleOrder = 2;
			nodeListPerEle = 1:6;
		case 'Q8'
			eleOrder = 2;
			nodeListPerEle = 1:8;
	end
	% paras = AvoidExactLocationAtVertexOrEdge4Robustness(paras, eleType, 1.0e-4);
	state_withinit = psl.mesh.CheckWhetherGivenNaturalCoordinatesWithinDomain(paras, eleType);
	if state_withinit
		iEleNodes = state_.eNodMat_(ele,nodeListPerEle);
		iEleNodeCoords = state_.nodeCoords_(iEleNodes,:);
		SF = psl.mesh.ShapeFunction(paras, eleType);
		phyCoord = SF * iEleNodeCoords;

		[localFrame, origin0, t1, t2] = psl.mesh.ComputeLocalFrameAtGivenPosition(paras, iEleNodeCoords, eleType);
		localCoord = [0 0];
			
		if state_.approxiInterp_
			localStressTensor = SF * state_.localStressFieldPerEle_(ele,:);
		else
			globalStressTensor = SF * state_.globalStressFieldPerEle_{ele};
			localStressTensor = psl.stress.GlobalFrame2Local_StressTensor(globalStressTensor, localFrame, 1);
		end
		localPrincipalStress = psl.stress.ComputePrincipalStressLocalFrame(localStressTensor);
		localVonMisesStress = psl.stress.ComputeVonMisesStressLocalFrame(localStressTensor);
	end
	seed0 = [ele paras];
	opt = state_withinit;
end

