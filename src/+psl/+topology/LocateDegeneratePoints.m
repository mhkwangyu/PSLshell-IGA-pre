function LocateDegeneratePoints()
%% 【论文 §4.1, Eq.24】定位退化点：偏应力向量 g=(f1,f2)=(½(σxx-σyy), σxy) 的零点
%% 即两主应力相等（莫尔圆半径=0）处。T6/Q8 细分子域各至多一根，共享边去重。
	global state_;
	global state_;
	global state_;
	
	numCandiEles = numel(state_.candidateElementsIncDegePts_);
	distilledCandidateElements = [];
	for ii=1:numCandiEles
		iEle = state_.candidateElementsIncDegePts_(ii);
		iEleType = state_.meshTypeMap_(iEle);
		switch iEleType
			case 'T3'
				[paras, isDegePt] = psl.topology.NewtonRhapson_LocatingDegPt(iEle, [0 0]);
				if isDegePt
					distilledCandidateElements(end+1,1:3) = [iEle paras(:)'];
				end				
			case 'Q4'
				[paras, isDegePt] = psl.topology.NewtonRhapson_LocatingDegPt(iEle, [0 0]);
				if isDegePt
					distilledCandidateElements(end+1,1:3) = [iEle paras(:)'];
				end						
			case 'T6'
				tmpDistilledCandiEle = [];
				[paras1, isDegePt1] = psl.topology.NewtonRhapson_LocatingDegPt(iEle, [0 0], 'T6_1');
				if isDegePt1
					tmpDistilledCandiEle(end+1,1:3) = [iEle paras1(:)'];
				end
				[paras2, isDegePt2] = psl.topology.NewtonRhapson_LocatingDegPt(iEle, [0 0], 'T6_2');
				if isDegePt2
					if isempty(tmpDistilledCandiEle)
						tmpDistilledCandiEle(end+1,1:3) = [iEle paras2(:)'];
					else
						if min(vecnorm(paras2(:)' - tmpDistilledCandiEle(:,2:3),2,2)) > 0.1 %%Additional Degenerate Point
							tmpDistilledCandiEle(end+1,1:3) = [iEle paras2(:)'];
						end
					end				
				end
				[paras3, isDegePt3] = psl.topology.NewtonRhapson_LocatingDegPt(iEle, [0 0], 'T6_3');
				if isDegePt3
					if isempty(tmpDistilledCandiEle)
						tmpDistilledCandiEle(end+1,1:3) = [iEle paras3(:)'];
					else
						if min(vecnorm(paras3(:)' - tmpDistilledCandiEle(:,2:3),2,2)) > 0.1 %%Additional Degenerate Points
							tmpDistilledCandiEle(end+1,1:3) = [iEle paras3(:)'];
						end
					end				
				end
				[paras4, isDegePt4] = psl.topology.NewtonRhapson_LocatingDegPt(iEle, [0 0], 'T6_4');
				if isDegePt4
					if isempty(tmpDistilledCandiEle)
						tmpDistilledCandiEle(end+1,1:3) = [iEle paras4(:)'];
					else
						if min(vecnorm(paras4(:)' - tmpDistilledCandiEle(:,2:3),2,2)) > 0.1 %%Additional Degenerate Points
							tmpDistilledCandiEle(end+1,1:3) = [iEle paras4(:)'];
						end						
					end
				end
				if ~isempty(tmpDistilledCandiEle)
					distilledCandidateElements(end+1:end+size(tmpDistilledCandiEle,1),:) = tmpDistilledCandiEle;
				end			
			case 'Q8'
				tmpDistilledCandiEle = [];
				[paras1, isDegePt1] = psl.topology.NewtonRhapson_LocatingDegPt(iEle, [0 0], 'Q8_1');
				if isDegePt1
					tmpDistilledCandiEle(end+1,1:3) = [iEle paras1(:)'];
				end
				[paras2, isDegePt2] = psl.topology.NewtonRhapson_LocatingDegPt(iEle, [0 0], 'Q8_2');
				if isDegePt2
					if isempty(tmpDistilledCandiEle)
						tmpDistilledCandiEle(end+1,1:3) = [iEle paras2(:)'];
					else
						if min(vecnorm(paras2(:)' - tmpDistilledCandiEle(:,2:3),2,2)) > 0.1 %%Additional Degenerate Point
							tmpDistilledCandiEle(end+1,1:3) = [iEle paras2(:)'];
						end
					end				
				end
				[paras3, isDegePt3] = psl.topology.NewtonRhapson_LocatingDegPt(iEle, [0 0], 'Q8_3');
				if isDegePt3
					if isempty(tmpDistilledCandiEle)
						tmpDistilledCandiEle(end+1,1:3) = [iEle paras3(:)'];
					else
						if min(vecnorm(paras3(:)' - tmpDistilledCandiEle(:,2:3),2,2)) > 0.1 %%Additional Degenerate Points
							tmpDistilledCandiEle(end+1,1:3) = [iEle paras3(:)'];
						end
					end				
				end
				[paras4, isDegePt4] = psl.topology.NewtonRhapson_LocatingDegPt(iEle, [0 0], 'Q8_4');
				if isDegePt4
					if isempty(tmpDistilledCandiEle)
						tmpDistilledCandiEle(end+1,1:3) = [iEle paras4(:)'];
					else
						if min(vecnorm(paras4(:)' - tmpDistilledCandiEle(:,2:3),2,2)) > 0.1 %%Additional Degenerate Points
							tmpDistilledCandiEle(end+1,1:3) = [iEle paras4(:)'];
						end						
					end
				end
				if ~isempty(tmpDistilledCandiEle)
					distilledCandidateElements(end+1:end+size(tmpDistilledCandiEle,1),:) = tmpDistilledCandiEle;
				end				
		end
	end
	if isempty(distilledCandidateElements), state_.degePts_ = []; return; end
	
	%% Merge Degenerate Point(s) Located at the element Edge
	numDistilledCandiEles = size(distilledCandidateElements, 1);
	validDegeneratePointsMap = false(numDistilledCandiEles,1);
	refCoords = [];
	for ii=1:numDistilledCandiEles
		iEle = distilledCandidateElements(ii,1);
		iPara = distilledCandidateElements(ii,2:3);
		iEleType = state_.meshTypeMap_(iEle);
		switch iEleType
			case 'T3'
				iEleNodes = state_.eNodMat_(iEle,1:3);
			case 'Q4'
				iEleNodes = state_.eNodMat_(iEle,1:4);
			case 'T6'
				iEleNodes = state_.eNodMat_(iEle,1:6);
			case 'Q8'
				iEleNodes = state_.eNodMat_(iEle,1:8);	
		end
		SF = psl.mesh.ShapeFunction(iPara, iEleType);
		iEleNodeCoords = state_.nodeCoords_(iEleNodes,:);
		iPhyCoord = SF * iEleNodeCoords;
		if 1==ii
			refCoords = iPhyCoord;
			validDegeneratePointsMap(ii) = true;
		else
			if min(vecnorm(iPhyCoord-refCoords, 2, 2)) > 1.0e-2*state_.refScalingSize_ %%Not the Same Degenerate Point
				refCoords(end+1,:) = iPhyCoord;
				validDegeneratePointsMap(ii) = true;
			end
		end
	end
	distilledCandidateElements = distilledCandidateElements(find(validDegeneratePointsMap),:);
	
	%%Setup Degenerate Point Structure
	numDegePts = size(distilledCandidateElements,1);
	state_.degePts_ = psl.topology.DegeneratePointStruct();
	state_.degePts_ = repmat(state_.degePts_, numDegePts, 1);
	for ii=1:numDegePts
		state_.degePts_(ii).eleIndex = distilledCandidateElements(ii,1);
		state_.degePts_(ii).paraCoord = distilledCandidateElements(ii,2:3);
		state_.degePts_(ii).phyCoord = refCoords(ii,:);
	end
end

