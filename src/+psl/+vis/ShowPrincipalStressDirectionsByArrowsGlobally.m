function ShowPrincipalStressDirectionsByArrowsGlobally(varargin)
%% 【结果可视化】用箭头显示主应力方向场（辅助自检）。
	global state_;
	global state_;
	global state_;
	
	if 1==nargin
		eleList = varargin{1};
		eleList = unique(eleList);
	else
		eleList = (1:state_.numEles_)';
	end
	volidEles = find(state_.voidEleMap_);
	eleList = setdiff(eleList, volidEles);
	
	numElesConsidered = numel(eleList);
	originList = zeros(numElesConsidered,3);
	dirMajorList = zeros(numElesConsidered,3);
	dirMinorList = zeros(numElesConsidered,3);
	
	opt_local2Global2Local = 1;
	for ii=1:numElesConsidered
		iEle = eleList(ii);
		switch state_.meshTypeMap_(iEle)
			case 'T3'
				paras = [1 1]/3;
				nodeListPerEle = 1:3;
				iEleNodes = state_.eNodMat_(iEle,nodeListPerEle);
				SF = psl.mesh.ShapeFunction(paras, 'T3');
				originList(ii,:) = SF * state_.nodeCoords_(iEleNodes, :);
				
				[iLocalFrame, ~, ~, ~] = psl.mesh.ComputeLocalFrameAtGivenPosition(paras, state_.nodeCoords_(iEleNodes, :), 'T3');
				iEleStressesLocal = state_.localStressFieldPerEle_{iEle};
				
				if opt_local2Global2Local
					iEleStressesGlobal = state_.globalStressFieldPerEle_{iEle};
					iStressTensorGlobal = SF * iEleStressesGlobal;
					iStressTensor = psl.stress.GlobalFrame2Local_StressTensor(iStressTensorGlobal, iLocalFrame, 1);
				else
					iStressTensor = SF * iEleStressesLocal;
				end
				
				iPSlocal = psl.stress.ComputePrincipalStressLocalFrame(iStressTensor);
				iMajor = iPSlocal(1,5:6); iMinor = iPSlocal(1,2:3);
				
				
				dirMajorList(ii,:) = psl.stress.GlobalFrame2Local_Vecs(iMajor, iLocalFrame, 0)';
				dirMinorList(ii,:) = psl.stress.GlobalFrame2Local_Vecs(iMinor, iLocalFrame, 0)';
			case 'Q4'
				paras = [0 0];
				nodeListPerEle = 1:4;
				iEleNodes = state_.eNodMat_(iEle,nodeListPerEle);
				SF = psl.mesh.ShapeFunction(paras, 'Q4');
				originList(ii,:) = SF * state_.nodeCoords_(iEleNodes, :);
				
				[iLocalFrame, ~, ~, ~] = psl.mesh.ComputeLocalFrameAtGivenPosition(paras, state_.nodeCoords_(iEleNodes, :), 'Q4');
				iEleStressesLocal = state_.localStressFieldPerEle_{iEle};
				
				if opt_local2Global2Local
					iEleStressesGlobal = state_.globalStressFieldPerEle_{iEle};
					iStressTensorGlobal = SF * iEleStressesGlobal;
					iStressTensor = psl.stress.GlobalFrame2Local_StressTensor(iStressTensorGlobal, iLocalFrame, 1);				
				else
					iStressTensor = SF * iEleStressesLocal;
				end
				
				iPSlocal = psl.stress.ComputePrincipalStressLocalFrame(iStressTensor);
				iMajor = iPSlocal(1,5:6); iMinor = iPSlocal(1,2:3);
	
				dirMajorList(ii,:) = psl.stress.GlobalFrame2Local_Vecs(iMajor, iLocalFrame, 0)';
				dirMinorList(ii,:) = psl.stress.GlobalFrame2Local_Vecs(iMinor, iLocalFrame, 0)';				
			case 'T6'
				paras = [1 1]/3;
				nodeListPerEle = 1:6;
				iEleNodes = state_.eNodMat_(iEle,nodeListPerEle);
				SF = psl.mesh.ShapeFunction(paras, 'T6');
				originList(ii,:) = SF * state_.nodeCoords_(iEleNodes, :);
				iEleStressesLocal = state_.localStressFieldPerEle_{iEle};
				[iLocalFrame, ~, ~, ~] = psl.mesh.ComputeLocalFrameAtGivenPosition(paras, state_.nodeCoords_(iEleNodes, :), 'T6');
				
				if opt_local2Global2Local
					iEleStressesGlobal = state_.globalStressFieldPerEle_{iEle};
					iStressTensorGlobal = SF * iEleStressesGlobal;
					iStressTensor = psl.stress.GlobalFrame2Local_StressTensor(iStressTensorGlobal, iLocalFrame, 1);					
				else
					iStressTensor = SF * iEleStressesLocal;
				end

				iPSlocal = psl.stress.ComputePrincipalStressLocalFrame(iStressTensor);
				iMajor = iPSlocal(1,5:6); iMinor = iPSlocal(1,2:3);	
				
				dirMajorList(ii,:) = psl.stress.GlobalFrame2Local_Vecs(iMajor, iLocalFrame, 0)';
				dirMinorList(ii,:) = psl.stress.GlobalFrame2Local_Vecs(iMinor, iLocalFrame, 0)';					
			case 'Q8'
				paras = [0 0];
				nodeListPerEle = 1:8;
				iEleNodes = state_.eNodMat_(iEle,nodeListPerEle);
				SF = psl.mesh.ShapeFunction(paras, 'Q8');
				originList(ii,:) = SF * state_.nodeCoords_(iEleNodes, :);
				iEleStressesLocal = state_.localStressFieldPerEle_{iEle};
				[iLocalFrame, ~, ~, ~] = psl.mesh.ComputeLocalFrameAtGivenPosition(paras, state_.nodeCoords_(iEleNodes, :), 'Q8');
				
				if opt_local2Global2Local
					iEleStressesGlobal = state_.globalStressFieldPerEle_{iEle};
					iStressTensorGlobal = SF * iEleStressesGlobal;
					iStressTensor = psl.stress.GlobalFrame2Local_StressTensor(iStressTensorGlobal, iLocalFrame, 1);						
				else
					iStressTensor = SF * iEleStressesLocal;
				end
				
				iPSlocal = psl.stress.ComputePrincipalStressLocalFrame(iStressTensor);
				iMajor = iPSlocal(1,5:6); iMinor = iPSlocal(1,2:3);
				
				dirMajorList(ii,:) = psl.stress.GlobalFrame2Local_Vecs(iMajor, iLocalFrame, 0)';
				dirMinorList(ii,:) = psl.stress.GlobalFrame2Local_Vecs(iMinor, iLocalFrame, 0)';					
		end
	end


	elesVis.vertices = state_.nodeCoords_;
	elesVis.faces = state_.silhouetteStruct_.faces(eleList,:);
	
	figure;
	hd_ele = patch(elesVis); hold on;
	hd_SampledPts = plot3(originList(:,1), originList(:,2), originList(:,3), '.r', 'LineWidth', 2, 'MarkerSize', 10); hold on;
	hd_major = quiver3(originList(:,1), originList(:,2), originList(:,3), dirMajorList(:,1), dirMajorList(:,2), dirMajorList(:,3), 'LineWidth', 1, 'Color', [252 141 98]/255); hold on;
	hd_major = quiver3(originList(:,1), originList(:,2), originList(:,3), dirMinorList(:,1), dirMinorList(:,2), dirMinorList(:,3), 'LineWidth', 1, 'Color', [0 176 80]/255);
	set(hd_ele, 'FaceColor', [204 204 204]/255, 'FaceAlpha', 1.0, 'EdgeColor', 'k', 'LineWidth', 2);
	if 0==sum(state_.nodeCoords_(:,3))
		view(2); %light	
	else
		view(3); %light	 
	end
	axis equal
end

