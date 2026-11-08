function ImportStressFields(fileName)
	global state_;
	global state_;
	global state_;
	
	%%1. Read mesh and cartesian stress field
	fid = fopen(fileName, 'r');
	%%1.1 Mesh
	% fgetl(fid);
	tmp = fscanf(fid, '%s', 1);
	dataVersionID = fscanf(fid, '%f', 1);
	tmp = fscanf(fid, '%s %s %s', 3);
	dataType = fscanf(fid, '%s', 1);
	switch dataType
		case 'NODE', state_.nodeWiseStressField_ = 1;
		case 'ELEMENT', state_.nodeWiseStressField_ = 0; %%Element-wise Stress Data
		otherwise, error('Un-supported Stress Data!');
	end
	domainType = fscanf(fid, '%s', 1);
	if ~strcmp(domainType, 'Shell'), error('Un-supported Data!'); end
	%meshType_ = fscanf(fid, '%s', 1);
	%if ~(strcmp(meshType_, 'Quad') || strcmp(meshType_, 'Tri') || strcmp(meshType_, 'Hybrid')), error('Un-supported Mesh!'); end
	state_.meshOrder_ = fscanf(fid, '%d', 1);
	if ~(1==state_.meshOrder_ || 2==state_.meshOrder_), error('Un-supported Mesh!'); end
	tmp = fscanf(fid, '%s', 1); state_.frameType_ = fscanf(fid, '%s', 1);
	if strcmp(state_.frameType_, 'LOCAL')
		tmp = fscanf(fid, '%s %s', 2); state_.refVec_ = fscanf(fid, '%e %e %e', [3, 1])';
		tmp = fscanf(fid, '%s %s', 2); state_.refVecFallback_ = fscanf(fid, '%e %e %e', [3, 1])';
	end
	startReadingVertices = fscanf(fid, '%s', 1);
	if ~strcmp(startReadingVertices, 'Vertices:'), error('Un-supported Data!'); end
	state_.numNodes_ = fscanf(fid, '%d', 1);
	state_.nodeCoords_ = fscanf(fid, '%e %e %e', [3, state_.numNodes_])'; 
	startReadingElements = fscanf(fid, '%s', 1);
	if ~strcmp(startReadingElements, 'Elements:'), error('Un-supported Data!'); end
	state_.numEles_ = fscanf(fid, '%d', 1);
	switch state_.meshOrder_
		case 1
			state_.eNodMat_ = NaN(state_.numEles_, 4);
			state_.meshTypeMap_ = repmat("Q4", state_.numEles_,1);
			for ii=1:state_.numEles_
				iNumNodesPerEle = fscanf(fid, '%d', 1);
				switch iNumNodesPerEle
					case 3
						state_.eNodMat_(ii,1:3) = fscanf(fid, '%d %d %d', [3, 1])';
						state_.meshTypeMap_(ii) = "T3";
					case 4
						state_.eNodMat_(ii,1:4) = fscanf(fid, '%d %d %d %d', [4, 1])';
				end
			end					
		case 2
			state_.eNodMat_ = NaN(state_.numEles_, 8);
			state_.meshTypeMap_ = repmat("Q8", state_.numEles_,1);
			for ii=1:state_.numEles_
				iNumNodesPerEle = fscanf(fid, '%d', 1);
				switch iNumNodesPerEle
					case 6
						state_.eNodMat_(ii,1:6) = fscanf(fid, '%d %d %d %d %d %d', [6, 1])';
						state_.meshTypeMap_(ii) = "T6";
					case 8
						state_.eNodMat_(ii,1:8) = fscanf(fid, '%d %d %d %d %d %d %d %d', [8, 1])';
				end
			end					
	end
	%%1.2 Stress Related
	startReadingLoads = fscanf(fid, '%s %s', 2); 
	if ~strcmp(startReadingLoads, 'NodeForces:'), error('Un-supported Data!'); end
	numLoadedNodes = fscanf(fid, '%d', 1);
	if numLoadedNodes>0, state_.loadingCond_ = fscanf(fid, '%d %e %e %e %e %e %e', [7, numLoadedNodes])'; else, loadingCond_ = []; end
	
	startReadingFixations = fscanf(fid, '%s %s', 2);
	if ~strcmp(startReadingFixations, 'FixedNodes:'), error('Un-supported Data!'); end
	numFixedNodes = fscanf(fid, '%d', 1);
	if numFixedNodes>0, state_.fixingCond_ = fscanf(fid, '%d %d %d %d %d %d %d', [7, numFixedNodes])'; else, fixingCond_ = []; end
	
	startReadingStress = fscanf(fid, '%s %s', 2); 
	if ~strcmp(startReadingStress, 'CartesianStress:'), error('Un-supported Data!'); end
	numValidNods = fscanf(fid, '%d', 1);
	switch state_.frameType_
		case 'LOCAL'
			%% Per-row: sigma_xx, sigma_yy, sigma_xy
			state_.localStressField_ = fscanf(fid, '%e %e %e', [3, numValidNods])';
		case 'GLOBAL'
			%% Per-row: sigma_xx, sigma_yy, sigma_zz, sigma_yz, sigma_zx, sigma_xy
			state_.globalStressField_ = fscanf(fid, '%e %e %e %e %e %e', [6, numValidNods])';
	end
	fclose(fid);	
end


