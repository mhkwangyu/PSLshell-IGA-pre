function ShowPSLs(stressCompBG, stressCompPSLs, lw, miniIntegralPts)
	%% Syntax:
	%% stressCompBG: %% 'None', 'Sigma_1', 'Sigma_2', 'Sigma_xx', 'Sigma_yy', 'Sigma_xy', 'Sigma_vM' ('Sigma_3', 'Sigma_zz', 'Sigma_xz', 'Sigma_yz', GLOBAL Stress Input) 
	%% stressCompPSLs: %% 'None', 'Sigma', 'Sigma_xx', 'Sigma_yy', 'Sigma_xy', 'Sigma_vM'
	%% ShowPSLs(stressCompBG, stressCompPSLs, lw, miniIntegralPts);
	global state_;
	global state_;

	%% Prepare PSLs for Vis
	tarIndice = [];
	for ii=1:numel(state_.majorPSLpool_)
		if state_.majorPSLpool_(ii).numIntergPts > miniIntegralPts, tarIndice(end+1,1) = ii; end
	end
	tarMajorPSLs = state_.majorPSLpool_(tarIndice);	
	numTarMajorPSLs = numel(tarMajorPSLs);
	
	tarIndice = [];
	for ii=1:numel(state_.minorPSLpool_)
		if state_.minorPSLpool_(ii).numIntergPts > miniIntegralPts, tarIndice(end+1,1) = ii; end
	end
	tarMinorPSLs = state_.minorPSLpool_(tarIndice);	
	numTarMinorPSLs = numel(tarMinorPSLs);
	numDege = numel(state_.degePts_);
	degePtPos = zeros(numDege,3);
	if numDege>0
		for ii=1:numDege
			degePtPos(ii,:) = state_.degePts_(ii).phyCoord;
			if 1==ii
				majorPSLs_TS = state_.degePts_(ii).majorSkeletons;
				minorPSLs_TS = state_.degePts_(ii).minorSkeletons;
			else
				majorPSLs_TS(end+1:end+numel(state_.degePts_(ii).majorSkeletons),1) = state_.degePts_(ii).majorSkeletons;
				minorPSLs_TS(end+1:end+numel(state_.degePts_(ii).minorSkeletons),1) = state_.degePts_(ii).minorSkeletons;
			end
		end
		tarIndiceTS = [];
		for ii=1:numel(majorPSLs_TS)
			if majorPSLs_TS(ii).numIntergPts > 2, tarIndiceTS(end+1,1) = ii; end
		end
		tarMajorPSLs_TS = majorPSLs_TS(tarIndiceTS);	
		numTarMajorPSLs_TS = numel(tarMajorPSLs_TS);
		tarIndiceTS = [];
		for ii=1:numel(minorPSLs_TS)
			if minorPSLs_TS(ii).numIntergPts > 2, tarIndiceTS(end+1,1) = ii; end
		end
		tarMinorPSLs_TS = minorPSLs_TS(tarIndiceTS);
		numTarMinorPSLs_TS = numel(tarMinorPSLs_TS);
	else
		tarMajorPSLs_TS = []; tarMinorPSLs_TS = [];
		numTarMajorPSLs_TS = 0; numTarMinorPSLs_TS = 0;
	end
	
	if 0==numTarMajorPSLs && 0==numTarMinorPSLs && 0==numTarMajorPSLs_TS && 0==numTarMinorPSLs_TS, return; end

	%% Setup Color Scheme
	switch stressCompBG
		case 'Sigma_1' %%Major Principal Stress
			switch state_.frameType_
				case 'LOCAL'
					tmp = psl.stress.ComputePrincipalStressLocalFrame(state_.localStressField_);
					cVal = tmp(:,4);					
				case 'GLOBAL'
					tmp = psl.stress.ComputePrincipalStressLocalFrame(state_.globalStressField_);
					cVal = tmp(:,9);						
			end		
		case 'Sigma_2' %%Minor (Medium for global) Principal Stress
			switch state_.frameType_
				case 'LOCAL'
					tmp = psl.stress.ComputePrincipalStressLocalFrame(state_.localStressField_);
					cVal = tmp(:,1);				
				case 'GLOBAL'
					tmp = psl.stress.ComputePrincipalStressLocalFrame(state_.globalStressField_);
					cVal = tmp(:,5);
			end		
		case 'Sigma_3' %%Minor Principal Stress
			if strcmp(state_.frameType_, 'GLOBAL')
				tmp = psl.stress.ComputePrincipalStressLocalFrame(state_.globalStressField_);
				cVal = tmp(:,1);
			else
				warning('Un-supported of the local stres field input!'); return;
			end
		case 'Sigma_vM' %%von Mises Stress
			switch state_.frameType_
				case 'LOCAL'
					cVal = psl.stress.ComputeVonMisesStressLocalFrame(state_.localStressField_);
				case 'GLOBAL'
					cVal = psl.stress.ComputeVonMisesStressLocalFrame(state_.globalStressField_);
			end		
		case 'Sigma_xx'
			switch state_.frameType_
				case 'LOCAL'
					cVal = state_.localStressField_(:,1);
				case 'GLOBAL'
					cVal = state_.globalStressField_(:,1);
			end		
		case 'Sigma_yy'
			switch state_.frameType_
				case 'LOCAL'
					cVal = state_.localStressField_(:,2);
				case 'GLOBAL'
					cVal = state_.globalStressField_(:,2);
			end		
		case {'Sigma_xy', 'Sigma_yx'}
			switch state_.frameType_
				case 'LOCAL'
					cVal = state_.localStressField_(:,3);
				case 'GLOBAL'
					cVal = state_.globalStressField_(:,6);
			end
		case 'Sigma_zz'
			if strcmp(state_.frameType_, 'GLOBAL')
				cVal = state_.globalStressField_(:,3);
			else
				warning('Un-supported of the local stres field input!'); return;
			end			
		case {'Sigma_xz', 'Sigma_zx'}
			if strcmp(state_.frameType_, 'GLOBAL')
				cVal = state_.globalStressField_(:,5);
			else
				warning('Un-supported of the local stres field input!'); return;
			end	
		case {'Sigma_yz', 'Sigma_zy'}
			if strcmp(state_.frameType_, 'GLOBAL')
				cVal = state_.globalStressField_(:,4);
			else
				warning('Un-supported of the local stres field input!'); return;
			end			
		case 'None'
			cVal = ones(state_.numNodes_,1);			
		otherwise
			warning('Wrong Input!');
	end
	minValCol = min(cVal);
	
	if ~strcmp(stressCompBG, 'None')
		stressCompPSLs = 'None';
	end
	color4MajorPSLs = struct('arr', []); color4MajorPSLs = repmat(color4MajorPSLs, numTarMajorPSLs, 1);
	color4MinorPSLs = struct('arr', []); color4MinorPSLs = repmat(color4MinorPSLs, numTarMinorPSLs, 1);
	color4MajorPSLs_TS = struct('arr', []); color4MajorPSLs_TS = repmat(color4MajorPSLs_TS, numTarMajorPSLs_TS, 1);
	color4MinorPSLs_TS = struct('arr', []); color4MinorPSLs_TS = repmat(color4MinorPSLs_TS, numTarMinorPSLs_TS, 1);	
	switch stressCompPSLs
		case 'None'
			for ii=1:numTarMajorPSLs
				color4MajorPSLs(ii).arr = minValCol*ones(1, tarMajorPSLs(ii).numIntergPts);
			end		
			for ii=1:numTarMinorPSLs
				color4MinorPSLs(ii).arr = minValCol*ones(1, tarMinorPSLs(ii).numIntergPts);
			end
			for ii=1:numTarMajorPSLs_TS
				color4MajorPSLs_TS(ii).arr = minValCol*ones(1, tarMajorPSLs_TS(ii).numIntergPts);
			end		
			for ii=1:numTarMinorPSLs_TS
				color4MinorPSLs_TS(ii).arr = minValCol*ones(1, tarMinorPSLs_TS(ii).numIntergPts);
			end			
		case 'Sigma'
			for ii=1:numTarMajorPSLs
				color4MajorPSLs(ii).arr = tarMajorPSLs(ii).localPrincipalStressList(:,4)';
			end	
			for ii=1:numTarMinorPSLs
				color4MinorPSLs(ii).arr = tarMinorPSLs(ii).localPrincipalStressList(:,1)';
			end
			for ii=1:numTarMajorPSLs_TS
				color4MajorPSLs_TS(ii).arr = tarMajorPSLs_TS(ii).localPrincipalStressList(:,4)';
			end	
			for ii=1:numTarMinorPSLs_TS
				color4MinorPSLs_TS(ii).arr = tarMinorPSLs_TS(ii).localPrincipalStressList(:,1)';
			end
			cVal = ones(size(cVal)) * min([[color4MajorPSLs.arr], [color4MinorPSLs.arr]]);
		case 'Sigma_xx'
			for ii=1:numTarMajorPSLs
				color4MajorPSLs(ii).arr = tarMajorPSLs(ii).localStressTensorList(:,1)';
			end
			for ii=1:numTarMinorPSLs
				color4MinorPSLs(ii).arr = tarMinorPSLs(ii).localStressTensorList(:,1)';
			end
			for ii=1:numTarMajorPSLs_TS
				color4MajorPSLs_TS(ii).arr = tarMajorPSLs_TS(ii).localStressTensorList(:,1)';
			end
			for ii=1:numTarMinorPSLs_TS
				color4MinorPSLs_TS(ii).arr = tarMinorPSLs_TS(ii).localStressTensorList(:,1)';
			end
			cVal = ones(size(cVal)) * min([[color4MajorPSLs.arr], [color4MinorPSLs.arr]]);
		case 'Sigma_yy'
			for ii=1:numTarMajorPSLs
				color4MajorPSLs(ii).arr = tarMajorPSLs(ii).localStressTensorList(:,2)';
			end	
			for ii=1:numTarMinorPSLs
				color4MinorPSLs(ii).arr = tarMinorPSLs(ii).localStressTensorList(:,2)';
			end
			for ii=1:numTarMajorPSLs_TS
				color4MajorPSLs_TS(ii).arr = tarMajorPSLs_TS(ii).localStressTensorList(:,2)';
			end	
			for ii=1:numTarMinorPSLs_TS
				color4MinorPSLs_TS(ii).arr = tarMinorPSLs_TS(ii).localStressTensorList(:,2)';
			end
			cVal = ones(size(cVal)) * min([[color4MajorPSLs.arr], [color4MinorPSLs.arr]]);
		case {'Sigma_xy', 'Sigma_yx'}
			for ii=1:numTarMajorPSLs
				color4MajorPSLs(ii).arr = tarMajorPSLs(ii).localStressTensorList(:,3)';
			end	
			for ii=1:numTarMinorPSLs
				color4MinorPSLs(ii).arr = tarMinorPSLs(ii).localStressTensorList(:,3)';
			end
			for ii=1:numTarMajorPSLs_TS
				color4MajorPSLs_TS(ii).arr = tarMajorPSLs_TS(ii).localStressTensorList(:,3)';
			end	
			for ii=1:numTarMinorPSLs_TS
				color4MinorPSLs_TS(ii).arr = tarMinorPSLs_TS(ii).localStressTensorList(:,3)';
			end	
			cVal = ones(size(cVal)) * min([[color4MajorPSLs.arr], [color4MinorPSLs.arr]]);
		case 'Sigma_vM'
			for ii=1:numTarMajorPSLs
				color4MajorPSLs(ii).arr = tarMajorPSLs(ii).localVonMisesStressList';
			end			
			for ii=1:numTarMinorPSLs
				color4MinorPSLs(ii).arr = tarMinorPSLs(ii).localVonMisesStressList';
			end
			for ii=1:numTarMajorPSLs_TS
				color4MajorPSLs_TS(ii).arr = tarMajorPSLs_TS(ii).localVonMisesStressList';
			end			
			for ii=1:numTarMinorPSLs_TS
				color4MinorPSLs_TS(ii).arr = tarMinorPSLs_TS(ii).localVonMisesStressList';
			end
			cVal = ones(size(cVal)) * min([[color4MajorPSLs.arr], [color4MinorPSLs.arr]]);
		otherwise
			error('Wrong Input!');			
	end	
	
	
	%%Draw
	figure; 
	handleSilhouette = patch(state_.silhouetteStruct_, 'FaceVertexCData', cVal); hold('on');

	lineWidthTube = lw*min(state_.boundingBox_(2,:)-state_.boundingBox_(1,:))/100;
	if 0==lineWidthTube %%2D
		majorPSLsGraph.vertices = [];
		majorPSLsGraph.faces = [];
		majorPSLsGraphColor = [];
		for jj=1:numel(tarMajorPSLs)
			if 1==jj
				majorPSLsGraph.vertices = tarMajorPSLs(jj).phyCoordList;
				majorPSLsGraph.faces = [1:tarMajorPSLs(jj).numIntergPts-1; 2:tarMajorPSLs(jj).numIntergPts]';
				majorPSLsGraphColor = color4MajorPSLs(jj).arr(:);
			else
				existingVertices = size(majorPSLsGraph.vertices,1);
				majorPSLsGraph.vertices(end+1:end+tarMajorPSLs(jj).numIntergPts,:) = tarMajorPSLs(jj).phyCoordList;
				majorPSLsGraph.faces(end+1:end+tarMajorPSLs(jj).numIntergPts-1,:) = existingVertices + [1:tarMajorPSLs(jj).numIntergPts-1; 2:tarMajorPSLs(jj).numIntergPts]';
				majorPSLsGraphColor(end+1:end+tarMajorPSLs(jj).numIntergPts,:) = color4MajorPSLs(jj).arr(:);
			end
		end
		if numTarMajorPSLs_TS > 0
			majorPSLsGraph_TS.vertices = [];
			majorPSLsGraph_TS.faces = [];
			majorPSLsGraphColor_TS = [];
			for jj=1:numel(tarMajorPSLs_TS)
				if 1==jj
					majorPSLsGraph_TS.vertices = tarMajorPSLs_TS(jj).phyCoordList;
					majorPSLsGraph_TS.faces = [1:tarMajorPSLs_TS(jj).numIntergPts-1; 2:tarMajorPSLs_TS(jj).numIntergPts]';
					majorPSLsGraphColor_TS = color4MajorPSLs_TS(jj).arr(:);
				else
					existingVertices = size(majorPSLsGraph_TS.vertices,1);
					majorPSLsGraph_TS.vertices(end+1:end+tarMajorPSLs_TS(jj).numIntergPts,:) = tarMajorPSLs_TS(jj).phyCoordList;
					majorPSLsGraph_TS.faces(end+1:end+tarMajorPSLs_TS(jj).numIntergPts-1,:) = existingVertices + [1:tarMajorPSLs_TS(jj).numIntergPts-1; 2:tarMajorPSLs_TS(jj).numIntergPts]';
					majorPSLsGraphColor_TS(end+1:end+tarMajorPSLs_TS(jj).numIntergPts,:) = color4MajorPSLs_TS(jj).arr(:);
				end
			end			
		end
		minorPSLsGraph.vertices = [];
		minorPSLsGraph.faces = [];
		minorPSLsGraphColor = [];
		for jj=1:numel(tarMinorPSLs)
			if 1==jj
				minorPSLsGraph.vertices = tarMinorPSLs(jj).phyCoordList;
				minorPSLsGraph.faces = [1:tarMinorPSLs(jj).numIntergPts-1; 2:tarMinorPSLs(jj).numIntergPts]';
				minorPSLsGraphColor = color4MinorPSLs(jj).arr(:);
			else
				existingVertices = size(minorPSLsGraph.vertices,1);
				minorPSLsGraph.vertices(end+1:end+tarMinorPSLs(jj).numIntergPts,:) = tarMinorPSLs(jj).phyCoordList;
				minorPSLsGraph.faces(end+1:end+tarMinorPSLs(jj).numIntergPts-1,:) = existingVertices + [1:tarMinorPSLs(jj).numIntergPts-1; 2:tarMinorPSLs(jj).numIntergPts]';
				minorPSLsGraphColor(end+1:end+tarMinorPSLs(jj).numIntergPts,:) = color4MinorPSLs(jj).arr(:);
			end
		end
		if numTarMinorPSLs_TS > 0
			minorPSLsGraph_TS.vertices = [];
			minorPSLsGraph_TS.faces = [];
			minorPSLsGraphColor_TS = [];
			for jj=1:numel(tarMinorPSLs_TS)
				if 1==jj
					minorPSLsGraph_TS.vertices = tarMinorPSLs_TS(jj).phyCoordList;
					minorPSLsGraph_TS.faces = [1:tarMinorPSLs_TS(jj).numIntergPts-1; 2:tarMinorPSLs_TS(jj).numIntergPts]';
					minorPSLsGraphColor_TS = color4MinorPSLs_TS(jj).arr(:);
				else
					existingVertices = size(minorPSLsGraph_TS.vertices,1);
					minorPSLsGraph_TS.vertices(end+1:end+tarMinorPSLs_TS(jj).numIntergPts,:) = tarMinorPSLs_TS(jj).phyCoordList;
					minorPSLsGraph_TS.faces(end+1:end+tarMinorPSLs_TS(jj).numIntergPts-1,:) = existingVertices + [1:tarMinorPSLs_TS(jj).numIntergPts-1; 2:tarMinorPSLs_TS(jj).numIntergPts]';
					minorPSLsGraphColor_TS(end+1:end+tarMinorPSLs_TS(jj).numIntergPts,:) = color4MinorPSLs_TS(jj).arr(:);
				end
			end		
		end
		handleMajorPSL = []; 
		if ~isempty(majorPSLsGraphColor)
			hold('on');
			handleMajorPSL = patch(majorPSLsGraph, 'FaceVertexCData', majorPSLsGraphColor);
		end
		handleMinorPSL = []; 
		if ~isempty(minorPSLsGraphColor)
			hold('on');
			handleMinorPSL = patch(minorPSLsGraph, 'FaceVertexCData', minorPSLsGraphColor);
		end
		handleMajorPSL_TS = [];
		if ~isempty(majorPSLsGraphColor_TS)
			hold('on');
			handleMajorPSL_TS = patch(majorPSLsGraph_TS, 'FaceVertexCData', majorPSLsGraphColor_TS);
		end
		handleMinorPSL_TS = []; 
		if ~isempty(minorPSLsGraphColor_TS)
			hold('on');
			handleMinorPSL_TS = patch(minorPSLsGraph_TS, 'FaceVertexCData', minorPSLsGraphColor_TS);
		end
		handleDegPot = [];
		if numDege > 0
			handleDegPot = plot3(degePtPos(:,1), degePtPos(:,2), degePtPos(:,3), 'o', 'Color', [112 48 160]/255, 'lineWidth', 5, 'MarkerSize', 20);
		end

		if strcmp(stressCompBG, 'None')
			if strcmp(stressCompPSLs, 'None')
				set(handleMajorPSL, 'FaceColor', 'None', 'EdgeColor', [252 141 98]/255, 'lineWidth', 3);
				set(handleMinorPSL, 'FaceColor', 'None', 'EdgeColor', [102 194 165]/255, 'lineWidth', 3); %[102 194 165]/255
				set(handleMajorPSL_TS, 'FaceColor', 'None', 'EdgeColor', [252 141 98]/255, 'lineWidth', 6);
				set(handleMinorPSL_TS, 'FaceColor', 'None', 'EdgeColor', [102 194 165]/255, 'lineWidth', 6);					
			else
				colormap('parula'); 
				%%Colorbar
				cb = colorbar('Location', 'east', 'AxisLocation','in');
				t=get(cb,'Limits'); 
				set(cb,'Ticks',linspace(t(1),t(2),5));
				L=cellfun(@(x)sprintf('%.2e',x),num2cell(linspace(t(1),t(2),5)),'Un',0); 
				set(cb,'xticklabel',L);
				set(handleMajorPSL, 'EdgeColor', 'interp', 'lineWidth', 3);
				set(handleMinorPSL, 'EdgeColor', 'interp', 'lineWidth', 3);
				set(handleMajorPSL_TS, 'EdgeColor', 'interp', 'lineWidth', 6);
				set(handleMinorPSL_TS, 'EdgeColor', 'interp', 'lineWidth', 6);					
			end
			set(handleSilhouette, 'faceColor', [0.9 0.9 0.9], 'FaceAlpha', 1.0, 'EdgeColor', 'None');
		else
			colormap('parula'); 
			%%Colorbar
			cb = colorbar('Location', 'east', 'AxisLocation','in');
			t=get(cb,'Limits'); 
			set(cb,'Ticks',linspace(t(1),t(2),5));
			L=cellfun(@(x)sprintf('%.2e',x),num2cell(linspace(t(1),t(2),5)),'Un',0); 
			set(cb,'xticklabel',L);			
			set(handleSilhouette, 'FaceColor', 'interp', 'FaceAlpha', 1.0, 'EdgeColor', 'none');	
			set(handleMajorPSL, 'FaceColor', 'None', 'EdgeColor', [252 141 98]/255, 'lineWidth', 3);
			set(handleMinorPSL, 'FaceColor', 'None', 'EdgeColor', [102 194 165]/255, 'lineWidth', 3);
			set(handleMajorPSL_TS, 'FaceColor', 'None', 'EdgeColor', [252 141 98]/255, 'lineWidth', 6);
			set(handleMinorPSL_TS, 'FaceColor', 'None', 'EdgeColor', [102 194 165]/255, 'lineWidth', 6);	
		end		
	else
		handleMajorPSL = []; 
		[gridX, gridY, gridZ, gridC, ~] = psl.vis.ExpandPSLs2Tubes(tarMajorPSLs, color4MajorPSLs, lineWidthTube);
		if ~isempty(gridX)
			hold('on'); 
			handleMajorPSL = surf(gridX, gridY, gridZ, gridC);
			shading('interp');
		end
		handleMajorPSL_TS = []; 
		[gridX, gridY, gridZ, gridC, ~] = psl.vis.ExpandPSLs2Tubes(tarMajorPSLs_TS, color4MajorPSLs_TS, 1.5*lineWidthTube);
		if ~isempty(gridX)
			hold('on'); 
			handleMajorPSL_TS = surf(gridX, gridY, gridZ, gridC);
			shading('interp');
		end
		handleMinorPSL = []; 
		[gridX, gridY, gridZ, gridC, ~] = psl.vis.ExpandPSLs2Tubes(tarMinorPSLs, color4MinorPSLs, lineWidthTube);
		if ~isempty(gridX)
			hold('on');
			handleMinorPSL = surf(gridX, gridY, gridZ, gridC);
			shading('interp');
		end
		handleMinorPSL_TS = []; 
		[gridX, gridY, gridZ, gridC, ~] = psl.vis.ExpandPSLs2Tubes(tarMinorPSLs_TS, color4MinorPSLs_TS, 1.5*lineWidthTube);
		if ~isempty(gridX)
			hold('on');
			handleMinorPSL_TS = surf(gridX, gridY, gridZ, gridC);
			shading('interp');
		end
		handleDegPot = [];
		if numDege > 0
			[patchX, patchY, patchZ] = psl.vis.GetSpheresOfPoints(degePtPos, 2.5*lineWidthTube);
			handleDegPot = surf(patchX, patchY, patchZ, min([[color4MajorPSLs.arr], [color4MinorPSLs.arr]])*ones(size(patchZ)));
		end
		if strcmp(stressCompBG, 'None')
			if strcmp(stressCompPSLs, 'None')
				set(handleMajorPSL, 'FaceColor', [252 141 98]/255, 'FaceAlpha', 1, 'EdgeAlpha', 0);
				set(handleMinorPSL, 'FaceColor', [102 194 165]/255, 'FaceAlpha', 1, 'EdgeAlpha', 0);
				set(handleMajorPSL_TS, 'FaceColor', [252 141 98]/255, 'FaceAlpha', 1, 'EdgeAlpha', 0);
				set(handleMinorPSL_TS, 'FaceColor', [102 194 165]/255, 'FaceAlpha', 1, 'EdgeAlpha', 0);							
			else
				colormap('parula'); 
				%%Colorbar
				cb = colorbar('Location', 'east', 'AxisLocation','in');
				t=get(cb,'Limits'); 
				set(cb,'Ticks',linspace(t(1),t(2),5));
				L=cellfun(@(x)sprintf('%.2e',x),num2cell(linspace(t(1),t(2),5)),'Un',0); 
				set(cb,'xticklabel',L);							
			end
			set(handleSilhouette, 'faceColor', [0.9 0.9 0.9], 'FaceAlpha', 1.0, 'EdgeColor', 'None');
			set(handleDegPot, 'FaceColor', [112 48 160]/255, 'FaceAlpha', 1, 'EdgeAlpha', 0);
		else
			colormap('parula'); 
			%%Colorbar
			cb = colorbar('Location', 'east', 'AxisLocation','in');
			t=get(cb,'Limits'); 
			set(cb,'Ticks',linspace(t(1),t(2),5));
			L=cellfun(@(x)sprintf('%.2e',x),num2cell(linspace(t(1),t(2),5)),'Un',0); 
			set(cb,'xticklabel',L);			
			set(handleSilhouette, 'FaceColor', 'interp', 'FaceAlpha', 1.0, 'EdgeColor', 'none');	
			
			set(handleMajorPSL, 'FaceColor', [252 141 98]/255, 'FaceAlpha', 1, 'EdgeAlpha', 0);
			set(handleMinorPSL, 'FaceColor', [102 194 165]/255, 'FaceAlpha', 1, 'EdgeAlpha', 0);
			set(handleMajorPSL_TS, 'FaceColor', [252 141 98]/255, 'FaceAlpha', 1, 'EdgeAlpha', 0);
			set(handleMinorPSL_TS, 'FaceColor', [102 194 165]/255, 'FaceAlpha', 1, 'EdgeAlpha', 0);	
			set(handleDegPot, 'FaceColor', [112 48 160]/255, 'FaceAlpha', 1, 'EdgeAlpha', 0);	%%[112 48 160]/255	
		end
	end
	
	% %%Lighting, Reflection
	if 0==lineWidthTube
		view(2);
		xlabel('X'); ylabel('Y');
	else
		view(3);
		lighting('gouraud');
		material('dull');
		camlight('headlight', 'infinite');
		xlabel('X'); ylabel('Y'); zlabel('Z');
	end
	axis('equal', 'tight', 'off');
	set(gca, 'FontName', 'Times New Roman', 'FontSize', 30);
end


