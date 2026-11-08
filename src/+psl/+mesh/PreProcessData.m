function PreProcessData()
%% 【论文 §2, §3】预处理：建单元质心、节点-单元邻接表(nodStruct)、单元-边-邻接(eleStruct)、
%% 剖分三角化、单元特征尺寸/曲率标定、以及 vis 用的 silhouette 等派生结构。
%% 这些连接表是 §3.2"沿共享边搬运"的高效实现基础。
	global state_;
	global state_;
	global state_;
	global state_;
	global state_;
	global state_;
	
	%%1. Extract Silhouette for Vis.
	state_.boundingBox_ = [min(state_.nodeCoords_, [], 1); max(state_.nodeCoords_, [], 1)];
	state_.silhouetteStruct_.vertices = state_.nodeCoords_;
	state_.silhouetteStruct_.faces = state_.eNodMat_;
	if 2==state_.meshOrder_
		state_.silhouetteStruct_.faces('Q8'==state_.meshTypeMap_,:) = state_.silhouetteStruct_.faces('Q8'==state_.meshTypeMap_,[1 5 2 6 3 7 4 8]);
		state_.silhouetteStruct_.faces('T6'==state_.meshTypeMap_,:) = state_.silhouetteStruct_.faces('T6'==state_.meshTypeMap_,[1 4 2 5 3 6 7 8]);	
	end
	state_.eleCentroids_ = zeros(state_.numEles_, 3);
	for ii=1:state_.numEles_
		iEleType = state_.meshTypeMap_(ii);
		switch iEleType
			case 'T3'
				iNumNodesPerEle = 3;
				iParas = [1 1]/3;
			case 'Q4'
				iNumNodesPerEle = 4;
				iParas = [0 0];
			case 'T6'
				iNumNodesPerEle = 6;
				iParas = [1 1]/3;
			case 'Q8'
				iNumNodesPerEle = 8;
				iParas = [0 0];
		end
		iSF = psl.mesh.ShapeFunction(iParas, iEleType);
		state_.eleCentroids_(ii,:) = iSF * state_.nodeCoords_(state_.eNodMat_(ii,1:iNumNodesPerEle),:);
	end
	
	%%2. Relate the Shared Element for each Vertex Node in unstructured shell mesh
	iNodStruct = struct('adjacentEles', []);
	state_.nodStruct_ = repmat(iNodStruct, state_.numNodes_, 1);
	for ii=1:state_.numEles_
		switch state_.meshTypeMap_(ii)
			case 'T3'
				iNumVertexNodesPerEle = 3;
			case 'Q4'
				iNumVertexNodesPerEle = 4;
			case 'T6'
				iNumVertexNodesPerEle = 3;
			case 'Q8'
				iNumVertexNodesPerEle = 4;
		end
		for jj=1:iNumVertexNodesPerEle
			state_.nodStruct_(state_.eNodMat_(ii,jj)).adjacentEles(1,end+1) = ii;
		end	
	end
	
	%%3. Relate the Shared Element of each Edge
	iEleStruct = struct('type', 0, 'edge2nextEle', zeros(1,4), 'edgeIDsOfNextEle', zeros(1,4), 'vtxEdgesGlobal', zeros(4,2));
	state_.eleStruct_ = repmat(iEleStruct, state_.numEles_, 1);
	for ii=1:state_.numEles_
		switch state_.meshTypeMap_(ii)
			case 'T3'
				state_.eleStruct_(ii).type = 3; %%T3
				iNumVertexEdgesPerEle = 3;
				iNodesPerEle = state_.eNodMat_(ii,1:3);
				edgePerEle = iNodesPerEle([1 2; 2 3; 3 1]);
				state_.eleStruct_(ii).edge2nextEle(end) = [];
				state_.eleStruct_(ii).edgeIDsOfNextEle(end) = [];
				state_.eleStruct_(ii).vtxEdgesGlobal = edgePerEle;
			case 'Q4'
				state_.eleStruct_(ii).type = 4; %%Q4
				iNumVertexEdgesPerEle = 4;
				iNodesPerEle = state_.eNodMat_(ii,1:4);
				edgePerEle = iNodesPerEle([1 2; 2 3; 3 4; 4 1]);
				state_.eleStruct_(ii).vtxEdgesGlobal = edgePerEle;
			case 'T6'
				state_.eleStruct_(ii).type = 6; %%T6
				iNumVertexEdgesPerEle = 3;
				iNodesPerEle = state_.eNodMat_(ii,1:3);
				edgePerEle = iNodesPerEle([1 2; 2 3; 3 1]);
				state_.eleStruct_(ii).edge2nextEle(end) = [];
				state_.eleStruct_(ii).edgeIDsOfNextEle(end) = [];
				state_.eleStruct_(ii).vtxEdgesGlobal(end,:) = [];
				state_.eleStruct_(ii).vtxEdgesGlobal = edgePerEle;
			case 'Q8'
				state_.eleStruct_(ii).type = 8; %%Q8
				iNumVertexEdgesPerEle = 4;
				iNodesPerEle = state_.eNodMat_(ii,1:4);
				edgePerEle = iNodesPerEle([1 2; 2 3; 3 4; 4 1]);
				state_.eleStruct_(ii).vtxEdgesGlobal = edgePerEle;
		end
		for jj=1:iNumVertexEdgesPerEle
			iEdge = edgePerEle(jj,:);
			eleGroup1 = state_.nodStruct_(iEdge(1)).adjacentEles;
			eleGroup2 = state_.nodStruct_(iEdge(2)).adjacentEles;
			sharedEles = intersect(eleGroup1, eleGroup2);
			numSharedEles = numel(sharedEles);				
			if 2==numSharedEles
				nextEle = setdiff(sharedEles, ii);
				if 1~=numel(nextEle)
					error('Un-expected Error in Mesh Structure 1!');
				end
				state_.eleStruct_(ii).edge2nextEle(jj) = nextEle;
				switch state_.meshTypeMap_(nextEle)
					case 'T3'
						iNodesNextEle = state_.eNodMat_(nextEle,1:3);
						edgesNextEle = iNodesNextEle([1 2; 2 3; 3 1]);
					case 'Q4'
						iNodesNextEle = state_.eNodMat_(nextEle,1:4);
						edgesNextEle = iNodesNextEle([1 2; 2 3; 3 4; 4 1]);
					case 'T6'
						iNodesNextEle = state_.eNodMat_(nextEle,1:3);
						edgesNextEle = iNodesNextEle([1 2; 2 3; 3 1]);					
					case 'Q8'
						iNodesNextEle = state_.eNodMat_(nextEle,1:4);
						edgesNextEle = iNodesNextEle([1 2; 2 3; 3 4; 4 1]);					
				end
				edgeInCurrentEle = sort(iEdge);
				edgesNextEle = sort(edgesNextEle,2);
				[~, localEdgeIDinNextEle] = intersect(edgesNextEle, edgeInCurrentEle, 'rows');
				state_.eleStruct_(ii).edgeIDsOfNextEle(jj) = localEdgeIDinNextEle;
			elseif 1==numSharedEles
				if sharedEles~=ii
					error('Un-expected Error in Mesh Structure 2!');
				end
			else
				error('Un-expected Error in Mesh Structure 3!');
			end
		end		
	end
	
	%%3.1 Extract Boundary Elements for Testing
	eleState = zeros(state_.numEles_,1);
	for ii=1:state_.numEles_
		if ~isempty(find(0==state_.eleStruct_(ii).edge2nextEle))
			eleState(ii) = 1;
		end
	end
	state_.boundaryElements_ = find(1==eleState);	
	
	%%4. Evaluate the Character Size of each Element (used in PSL tracing process)
	%% Roughly Minimum Edge
	state_.eleCharacterSizeList_ = zeros(state_.numEles_,1);
	for ii=1:state_.numEles_
		switch state_.meshTypeMap_(ii)
			case 'T3'
				iNodesPerEle = state_.eNodMat_(ii,1:3);
				edgePerEle = [1 2; 2 3; 3 1];
			case 'Q4'
				iNodesPerEle = state_.eNodMat_(ii,1:4);
				edgePerEle = [1 2; 2 3; 3 4; 4 1];
			case 'T6'
				iNodesPerEle = state_.eNodMat_(ii,1:3);
				edgePerEle = [1 2; 2 3; 3 1];
			case 'Q8'
				iNodesPerEle = state_.eNodMat_(ii,1:4);
				edgePerEle = [1 2; 2 3; 3 4; 4 1];
		end
		iEleNodeCoords = state_.nodeCoords_(iNodesPerEle,:);
		iEleEdgeLengths = vecnorm(iEleNodeCoords(edgePerEle(:,2),:)-iEleNodeCoords(edgePerEle(:,1),:),2,2);
		state_.eleCharacterSizeList_(ii) = min(iEleEdgeLengths);
	end
	state_.refScalingSize_ = mean(state_.eleCharacterSizeList_);	
	
	%%5. Evaluate the Curvature of each higher-order Element (used in PSL tracing process, scale the tracing step size)
	%% Rougly Maximum Directional Deviation of the Sampled Shell Normals per Element
	%% Scaling range: 1-5
	maxScalingFactor = 5;
	state_.shellEleNormals_ = struct('normals', [], 'paras', []);
	state_.shellEleNormals_ = repmat(state_.shellEleNormals_, state_.numEles_, 1);
	state_.shellCurvatureScaling_ = ones(state_.numEles_, 1);
	if state_.meshOrder_>1
		for ii=1:state_.numEles_
			switch state_.meshTypeMap_(ii)
				case 'T6'
					iEleNodes = state_.nodeCoords_(state_.eNodMat_(ii,1:6),:);
					sampledPts = [
						1/3		1/3
						1/6		1/6
						2/3		1/6
						1/6		2/3
					];
					[faceNormList, ~, ~] = psl.mesh.ComputeNormalsAtGivenPosition(sampledPts, iEleNodes, 'T6');
				case 'Q8'
					iEleNodes = state_.nodeCoords_(state_.eNodMat_(ii,:),:);
					sampledPts = [ %%Natural Coordinates
						 0.0	 			 0.0
						-0.5773502691896258	-0.5773502691896258
						 0.5773502691896258	-0.5773502691896258
						 0.5773502691896258	 0.5773502691896258
						-0.5773502691896258	 0.5773502691896258
					];
					[faceNormList, ~, ~] = psl.mesh.ComputeNormalsAtGivenPosition(sampledPts, iEleNodes, 'Q8');
			end
			state_.shellEleNormals_(ii).normal = faceNormList;
			state_.shellEleNormals_(ii).paras = sampledPts;
			
			refNorm = faceNormList(1,:);
			testNorm = faceNormList(2:end,:);
			dirEval = acos(sum(refNorm .* testNorm, 2));
			iMaxDirDev = max(dirEval);
			if iMaxDirDev > 45
				warning(['Element ', sprintf('%4i',ii), ' is highly curved!']);
			end
			state_.shellCurvatureScaling_(ii) = max(iMaxDirDev, 1);
		end
	end
	maxDirectionalDev = max(state_.shellCurvatureScaling_);
	if maxDirectionalDev > 1
		tmp = 1 + (maxScalingFactor-1)*(state_.shellCurvatureScaling_-1)/(maxDirectionalDev-1);
		state_.shellCurvatureScaling_ = tmp;
	end
	
	%%6. Pre-compute per-element Node Stress Tensors in Global
	state_.localStressFieldPerEle_ = cell(state_.numEles_,1);
	state_.globalStressFieldPerEle_ = cell(state_.numEles_,1);
	state_.voidEleMap_ = false(state_.numEles_,1);
	for ii=1:state_.numEles_
		iEleType = state_.meshTypeMap_(ii);
		switch iEleType
			case 'T3'
				iEleNodes = state_.eNodMat_(ii,1:3);
				parasNodes = [0.0 0.0; 1.0 0.0; 0.0 1.0];
				iEleNodeCoords = state_.nodeCoords_(iEleNodes,:);
				nodeLocalFrames = zeros(3,3,3);
				for jj=1:3
					[nodeLocalFrames(:,:,jj), ~, ~, ~] = psl.mesh.ComputeLocalFrameAtGivenPosition(parasNodes(jj,:), iEleNodeCoords, iEleType);
				end				
			case 'Q4'
				iEleNodes = state_.eNodMat_(ii,1:4);
				parasNodes = [-1.0 -1.0; 1.0 -1.0; 1.0 1.0; -1.0 1.0];
				iEleNodeCoords = state_.nodeCoords_(iEleNodes,:);	
				nodeLocalFrames = zeros(3,3,4);
				for jj=1:4
					[nodeLocalFrames(:,:,jj), ~, ~, ~] = psl.mesh.ComputeLocalFrameAtGivenPosition(parasNodes(jj,:), iEleNodeCoords, iEleType);
				end						
			case 'T6'
				iEleNodes = state_.eNodMat_(ii,1:6);
				parasNodes = [0.0 0.0; 1.0 0.0; 0.0 1.0; 0.5 0.0; 0.5 0.5; 0.0 0.5];
				iEleNodeCoords = state_.nodeCoords_(iEleNodes,:);	
				nodeLocalFrames = zeros(3,3,6);
				for jj=1:6
					[nodeLocalFrames(:,:,jj), ~, ~, ~] = psl.mesh.ComputeLocalFrameAtGivenPosition(parasNodes(jj,:), iEleNodeCoords, iEleType);
				end				
			case 'Q8'
				iEleNodes = state_.eNodMat_(ii,1:8);
				parasNodes = [-1.0 -1.0; 1.0 -1.0; 1.0 1.0; -1.0 1.0; 0.0 -1.0; 1.0 0.0; 0.0 1.0; -1.0 0.0];
				iEleNodeCoords = state_.nodeCoords_(iEleNodes,:);				
				nodeLocalFrames = zeros(3,3,8);
				for jj=1:8
					[nodeLocalFrames(:,:,jj), ~, ~, ~] = psl.mesh.ComputeLocalFrameAtGivenPosition(parasNodes(jj,:), iEleNodeCoords, iEleType);
				end							
		end
		switch state_.frameType_
			case 'LOCAL'
				iEleStressesLocal = state_.localStressField_(iEleNodes,:);
				iEleStressesGlobal = psl.stress.GlobalFrame2Local_StressTensor(iEleStressesLocal, nodeLocalFrames, 0);	
			case 'GLOBAL'
				iEleStressesGlobal = state_.globalStressField_(iEleNodes,:);
				iEleStressesLocal = psl.stress.GlobalFrame2Local_StressTensor(iEleStressesGlobal, nodeLocalFrames, 1);					
		end
		state_.localStressFieldPerEle_{ii} = iEleStressesLocal;
		state_.globalStressFieldPerEle_{ii} = iEleStressesGlobal;
		if ~isempty(find(0==psl.stress.ComputeVonMisesStressLocalFrame(iEleStressesLocal)))
			state_.voidEleMap_(ii) = true;
		end
	end	

	%%7. Triangulation for Geodesic Distance Computing
	elesQ8 = find('Q8'==state_.meshTypeMap_);
	if ~isempty(elesQ8)
		numQ8eles = numel(elesQ8);
		newlyInsertedNodes = zeros(numQ8eles, 3);
		Q8SFctr = psl.mesh.ShapeFunction([0 0], 'Q8');
		for ii=1:numQ8eles
			iEleNodes = state_.eNodMat_(elesQ8(ii),1:8);
			iEleNodeCoords = state_.nodeCoords_(iEleNodes,:);
			newlyInsertedNodes(ii,:) = Q8SFctr * iEleNodeCoords;
		end
		mapQ8 = zeros(state_.numEles_,1);
		mapQ8(elesQ8,1) = (1:numel(elesQ8))';
	else
		newlyInsertedNodes = [];
		mapQ8 = (1:state_.numEles_)';
	end
	triangularizedNodeCoords = [state_.nodeCoords_; newlyInsertedNodes];
	triangularizedElementsTmp = struct('arr', []);
	triangularizedElementsTmp = repmat(triangularizedElementsTmp, state_.numEles_, 1);
	
	for ii=1:state_.numEles_
		iEleType = state_.meshTypeMap_(ii);
		switch iEleType
			case 'T3'
				iEleNodes = state_.eNodMat_(ii,1:3);
			case 'Q4'
				iEleNodes = state_.eNodMat_(ii,1:4);
				iEleNodes = iEleNodes([1 2 3  3 4 1]);
			case 'T6'
				iEleNodes = state_.eNodMat_(ii,1:6);
				iEleNodes = iEleNodes([1 4 6  4 2 5  6 5 3  4 5 6]);
			case 'Q8'
				iEleNodes = zeros(1,9);
				iEleNodes(1:8) = state_.eNodMat_(ii,1:8);
				iEleNodes(9) = state_.numNodes_+mapQ8(ii);
				iEleNodes = iEleNodes([1 5 8  9 8 5  5 2 9  6 9 2  9 6 7  3 7 6  8 9 4  7 4 9]);
		end
		triangularizedElementsTmp(ii).arr = iEleNodes;
	end
	triangularizedElements = [triangularizedElementsTmp.arr]';
	numTriangularizedEles = numel(triangularizedElements)/3;
	triangularizedElements = reshape(triangularizedElements, 3, numTriangularizedEles)';
	state_.triangularizedMesh_ = triangulation(triangularizedElements, triangularizedNodeCoords);
	triangularizedMeshEdges = edges(state_.triangularizedMesh_);
	weights = vecnorm(triangularizedNodeCoords(triangularizedMeshEdges(:,1),:) - triangularizedNodeCoords(triangularizedMeshEdges(:,2),:), 2, 2);
	state_.triangularizedMeshGraph_ = graph(triangularizedMeshEdges(:,1), triangularizedMeshEdges(:,2), weights);
end


