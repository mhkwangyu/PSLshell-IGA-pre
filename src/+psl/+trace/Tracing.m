function [phyCoordList, eleIndexList, paraCoordList, localFrameList, localStressTensorList, localPrincipalStressList, ...
	localVonMisesStressList] = Tracing(e0, paraCoord0, localFrame0, t1, t2, v0, psDir)
	global state_;
	global state_;
	global state_;

	phyCoordList = zeros(state_.limitSteps_,3);
	tangentList = zeros(state_.limitSteps_,3);
	eleIndexList = zeros(state_.limitSteps_,1);
	paraCoordList = zeros(state_.limitSteps_,2);
	localFrameList = zeros(3,3,state_.limitSteps_);
	localStressTensorList = zeros(state_.limitSteps_,3);
	localPrincipalStressList = zeros(state_.limitSteps_,6);
	localVonMisesStressList = zeros(state_.limitSteps_,1);
	
	[e0, paraCoord0, localFrame0, t1, t2, v0] = psl.trace.SeedSecurityCheck4Robustness(e0, paraCoord0, localFrame0, t1, t2, v0);
	if state_.voidEleMap_(e0), e0 = 0; end
	index = 0;
	reachingBoundary = false;
    eStart = state_.eleStruct_(e0).edge2nextEle;
	switch state_.tracingSche_
		case 'Euler'
			while e0 && index<=state_.limitSteps_ && ~reachingBoundary
				e0Type = state_.meshTypeMap_(e0);
				tracingStepSize = state_.eleCharacterSizeList_(e0)/state_.scalingStepSize4PSL_/state_.shellCurvatureScaling_(e0);
				localCoordIncrement = tracingStepSize*v0;
				paraCoordIncrement = psl.trace.ComputeIncrementOfNaturalCoordFromIncrementOfLocalCoord(localCoordIncrement, localFrame0, t1(:), t2(:));
				paraCoord1 = paraCoord0 + paraCoordIncrement;
				inside_e0 = psl.mesh.CheckWhetherGivenNaturalCoordinatesWithinDomain(paraCoord1, e0Type);
				eRef = e0;
				if ~inside_e0
					indexLocal = 0;
					[e0, e0Type, paraCoord1, e0_edgeIDlocal, optAtBoundary, ~] = psl.trace.EdgeSituationProcessing(e0, paraCoord0, paraCoord1, e0Type);
					if optAtBoundary, break; end
				end
				
				%%Advance Point
				index = index + 1;
				[iPhyCoord, iLocalFrame, t1, t2, iStressTensor, iVonMisesStress, iPrincipalStress] = psl.trace.RetrievePhyInfoAtUpdatedPt(e0, paraCoord1, e0Type);
				phyCoordList(index,:) = iPhyCoord;
				eleIndexList(index,1) = e0;
				paraCoordList(index,:) = paraCoord1;
				localFrameList(:,:,index) = iLocalFrame;
				localStressTensorList(index,:) = iStressTensor;
				localPrincipalStressList(index,:) = iPrincipalStress;
				localVonMisesStressList(index,1) = iVonMisesStress;		
				
				%% Temination Condition
				if inside_e0
					[v1, terminationCond] = psl.trace.BidirectionalFeatureProcessing(v0, iPrincipalStress(psDir), localFrame0, iLocalFrame);            
                else
					[v1, terminationCond] = psl.trace.BidirectionalFeatureProcessing_Advanced(v0, iPrincipalStress(psDir), localFrame0, iLocalFrame, eRef, e0_edgeIDlocal);				
                end
                
				tangentList(index,:) = psl.stress.GlobalFrame2Local_Vecs(v1, iLocalFrame, 0);
				if terminationCond, index = index-1; break; end
                if index > 100 && isempty(setdiff(e0, eStart)), break; end
				v0 = v1;
				paraCoord0 = paraCoord1;
				localFrame0 = iLocalFrame;
			end		
		case 'RK2'
			while e0 && index<=state_.limitSteps_ && ~reachingBoundary
				e0Type = state_.meshTypeMap_(e0);
				tracingStepSize = state_.eleCharacterSizeList_(e0)/state_.scalingStepSize4PSL_/state_.shellCurvatureScaling_(e0);
				localCoordIncrement = tracingStepSize*v0;
				paraCoordIncrement = psl.trace.ComputeIncrementOfNaturalCoordFromIncrementOfLocalCoord(localCoordIncrement, localFrame0, t1(:), t2(:)); %%k1
				paraCoord1 = paraCoord0 + paraCoordIncrement;
				inside_e0 = psl.mesh.CheckWhetherGivenNaturalCoordinatesWithinDomain(paraCoord1, e0Type);
				eRef = e0;
				if ~inside_e0
					[~, ~, ~, e0_edgeIDlocal, optAtBoundary, paraCoord1e0] = psl.trace.EdgeSituationProcessing(e0, paraCoord0, paraCoord1, e0Type);		
					if optAtBoundary, break; end
					k1 = paraCoord1e0 - paraCoord0;
				else
					k1 = paraCoordIncrement;
				end
				
				%%Evaluate at Mid-point
				midPot = paraCoord0 + k1/2;
				[~, iLocalFrame_midPot, t1_midPot, t2_midPot, ~, ~, iPrincipalStress_midPot] = ...
					psl.trace.RetrievePhyInfoAtUpdatedPt(eRef, midPot, e0Type);
				[v1_midPot, ~] = psl.trace.BidirectionalFeatureProcessing(v0, iPrincipalStress_midPot(psDir), localFrame0, iLocalFrame_midPot);
				localCoordIncrement2 = tracingStepSize * v1_midPot;
				paraCoordIncrement2 = psl.trace.ComputeIncrementOfNaturalCoordFromIncrementOfLocalCoord(localCoordIncrement2, iLocalFrame_midPot, t1_midPot(:), t2_midPot(:)); 
				paraCoord2 = paraCoord0 + paraCoordIncrement2;
				inside_e0 = psl.mesh.CheckWhetherGivenNaturalCoordinatesWithinDomain(paraCoord2, e0Type);

				if ~inside_e0
					[e0, e0Type, paraCoord2, e0_edgeIDlocal, optAtBoundary] = psl.trace.EdgeSituationProcessing(e0, paraCoord0, paraCoord2, e0Type);
					if optAtBoundary, break; end
				end
				
				%%Advance Point
				index = index + 1;
				[iPhyCoord, iLocalFrame, t1, t2, iStressTensor, iVonMisesStress, iPrincipalStress] = psl.trace.RetrievePhyInfoAtUpdatedPt(e0, paraCoord2, e0Type);
				phyCoordList(index,:) = iPhyCoord;
				eleIndexList(index,1) = e0;
				paraCoordList(index,:) = paraCoord2;
				localFrameList(:,:,index) = iLocalFrame;
				localStressTensorList(index,:) = iStressTensor;
				localPrincipalStressList(index,:) = iPrincipalStress;
				localVonMisesStressList(index,1) = iVonMisesStress;
	
				%% Temination Condition
				if inside_e0
					[v1, terminationCond] = psl.trace.BidirectionalFeatureProcessing(v0, iPrincipalStress(psDir), localFrame0, iLocalFrame);
				else
					[v1, terminationCond] = psl.trace.BidirectionalFeatureProcessing_Advanced(v0, iPrincipalStress(psDir), localFrame0, iLocalFrame, eRef, e0_edgeIDlocal);
                end			
				tangentList(index,:) = psl.stress.GlobalFrame2Local_Vecs(v1, iLocalFrame, 0);
				if terminationCond, index = index-1; break; end
                if index > 100 && isempty(setdiff(e0, eStart)), break; end
				v0 = v1;
				paraCoord0 = paraCoord2;
				localFrame0 = iLocalFrame;				
			end		
	end

	phyCoordList = phyCoordList(1:index,:);
	tangentList = tangentList(1:index,:);
	eleIndexList = eleIndexList(1:index,1);
	paraCoordList = paraCoordList(1:index,:);
	localFrameList = localFrameList(:,:,1:index);
	localStressTensorList = localStressTensorList(1:index,:);
	localPrincipalStressList = localPrincipalStressList(1:index,:);
	localVonMisesStressList = localVonMisesStressList(1:index,1);		
end

