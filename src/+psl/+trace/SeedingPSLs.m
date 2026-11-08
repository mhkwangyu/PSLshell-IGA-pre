function SeedingPSLs(profile)
%% 【论文 §5, 图10】拓扑感知播种主循环（ref. 3D-TSV 价态机制）。
%% 每个种子带二值价态 [major被主PSL穿过, minor被次PSL穿过]，"边画边记账"：
%% 一条 PSL 生成后合并阈值内种子、置对应价态=1；骨架优先嵌入，再铺满全域。
%% 间距阈值 = D_min / PSLsDensityCtrl（ω 越大越密）。
	global state_;
	global state_;
	global state_;
	global state_;
	
	%%1. Initialization
	state_.limitSteps_ = profile.maxIts;
	state_.distanceMetric_ = profile.distanceMetric;
	state_.iniSeedPoints_ = psl.trace.SetupSeeds(profile.seedSparsityCtrl);
	state_.seedPoints_ = state_.iniSeedPoints_;
	state_.seedPointsRef_ = [state_.seedPoints_(:,1) state_.eleCentroids_(state_.seedPoints_(:,1),:)];
	numSeedPoints = size(state_.iniSeedPoints_,1);
	assert(2==numel(profile.PSLtypeCtrl));
	state_.seedPointsValence_ = repmat(profile.PSLtypeCtrl(:)', numSeedPoints, 1);
	state_.mergingThreshold_ = min(state_.boundingBox_(2,:)-state_.boundingBox_(1,:))/profile.PSLsDensityCtrl;
	if 0==state_.mergingThreshold_ %%2D
		state_.mergingThreshold_ = max(state_.boundingBox_(2,:)-state_.boundingBox_(1,:))/profile.PSLsDensityCtrl;
	end
	
	state_.majorPSLpool_ = psl.trace.PrincipalStressLineStruct();
	state_.minorPSLpool_ = psl.trace.PrincipalStressLineStruct();
	state_.majorCoordList_ = [];	
	state_.minorCoordList_ = [];
	% ShowSeedingProcess(0.75);	
	[~, startEle] = min(vecnorm(sum(state_.boundingBox_, 1)/2-state_.eleCentroids_, 2, 2));
	startCoord = state_.eleCentroids_(startEle,:);
	
	%%2. Topology Analysis
	if profile.topologyAware
		psl.topology.StressTopologyAnalysis();
		psl.trace.EmbedTopologicalSkeleton();
	end
	% ShowSeedingProcess(0.75);	
	%%3. Seeding (ref. 3D-TSV)
	its = 0;
	looper = sum(state_.seedPointsValence_(:));
	while looper<2*numSeedPoints
		its = its + 1;
		valenceMetric = sum(state_.seedPointsValence_,2);
		unFinishedSpps = find(valenceMetric<2);
		% spp = unFinishedSpps(1);
		if 0==looper
			[~, spp] = min(vecnorm(startCoord-state_.seedPointsRef_(:,end-2:end),2,2));
		else
			tmp	= state_.seedPointsValence_(unFinishedSpps,:);
			tmp = find(1==sum(tmp,2));
			if ~isempty(tmp), unFinishedSpps = unFinishedSpps(tmp); end
			[~, tarPos] = min(vecnorm(startCoord-state_.seedPointsRef_(unFinishedSpps,end-2:end),2,2));
			spp = unFinishedSpps(tarPos);
		end
		valences = state_.seedPointsValence_(spp,:);
		iSeed = state_.seedPoints_(spp,:);
		if 0==valences(1)
			state_.seedPointsValence_(spp,1) = 1;
			majorPSL = psl.trace.CreatePrincipalStressLine(iSeed, 'MAJOR');
			if 0==majorPSL.numIntergPts
				looper = sum(state_.seedPointsValence_(:)); 
				disp([' Iteration.: ' sprintf('%4i',its) ' Progress.: ' sprintf('%6i',looper) ...
					' Total.: ' sprintf('%6i',2*numSeedPoints)]); continue; 			
			end
			state_.majorPSLpool_(end+1,1) = majorPSL;
			state_.majorCoordList_(end+1:end+majorPSL.numIntergPts,:) = majorPSL.phyCoordList;
			sppsEmptyMajorValence = find(0==state_.seedPointsValence_(:,1));
			if ~isempty(sppsEmptyMajorValence)
				[potentialDisListMajor, potentialPosListMajor, potentialPosListMajorPara] = psl.trace.GetDisListOfPointList2Curve(...	
					state_.seedPointsRef_(sppsEmptyMajorValence,:), [majorPSL.eleIndexList majorPSL.phyCoordList], [majorPSL.eleIndexList majorPSL.paraCoordList]);
				potentialSolidSppsMajor = find(potentialDisListMajor<state_.mergingThreshold_);
				if ~isempty(potentialSolidSppsMajor)
					spps2BeMerged = sppsEmptyMajorValence(potentialSolidSppsMajor);							
					state_.seedPointsRef_(spps2BeMerged,:) = potentialPosListMajor(potentialSolidSppsMajor,:);
					state_.seedPoints_(spps2BeMerged,:) = potentialPosListMajorPara(potentialSolidSppsMajor,:);
					state_.seedPointsValence_(spps2BeMerged,1) = 1;											
					modifiedMinorValences = psl.trace.HighCurvatureModification(spps2BeMerged, 'MINOR');
					state_.seedPointsValence_(modifiedMinorValences,2) = 1;							
				end				
			end
		end
		
		if 0==valences(2)
			state_.seedPointsValence_(spp,2) = 1;
			minorPSL = psl.trace.CreatePrincipalStressLine(iSeed, 'MINOR');
			if 0==minorPSL.numIntergPts
				looper = sum(state_.seedPointsValence_(:)); 
				disp([' Iteration.: ' sprintf('%4i',its) ' Progress.: ' sprintf('%6i',looper) ...
					' Total.: ' sprintf('%6i',2*numSeedPoints)]); continue; 			
			end
			state_.minorPSLpool_(end+1,1) = minorPSL;
			state_.minorCoordList_(end+1:end+minorPSL.numIntergPts,:) = minorPSL.phyCoordList;
			sppsEmptyMinorValence = find(0==state_.seedPointsValence_(:,2));
			if ~isempty(sppsEmptyMinorValence)
				[potentialDisListMinor, potentialPosListMinor, potentialPosListMinorPara] = psl.trace.GetDisListOfPointList2Curve(...	
					state_.seedPointsRef_(sppsEmptyMinorValence,:), [minorPSL.eleIndexList minorPSL.phyCoordList], [minorPSL.eleIndexList minorPSL.paraCoordList]);
				potentialSolidSppsMinor = find(potentialDisListMinor<state_.mergingThreshold_);
				if ~isempty(potentialSolidSppsMinor)
					spps2BeMerged = sppsEmptyMinorValence(potentialSolidSppsMinor);
					state_.seedPointsRef_(spps2BeMerged,:) = potentialPosListMinor(potentialSolidSppsMinor,:);
					state_.seedPoints_(spps2BeMerged,:) = potentialPosListMinorPara(potentialSolidSppsMinor,:);
					state_.seedPointsValence_(spps2BeMerged,2) = 1;
					modifiedMajorValences = psl.trace.HighCurvatureModification(spps2BeMerged, 'MAJOR');
					state_.seedPointsValence_(modifiedMajorValences,1) = 1;	
				end
			end
		end
		looper = sum(state_.seedPointsValence_(:));
		disp([' Iteration.: ' sprintf('%4i',its) ' Progress.: ' sprintf('%6i',looper) ...
			' Total.: ' sprintf('%6i',2*numSeedPoints)]);	
		% ShowSeedingProcess(0.75);	
	end
	state_.majorPSLpool_ = psl.trace.CompactStreamlines(state_.majorPSLpool_, 5);
	state_.minorPSLpool_ = psl.trace.CompactStreamlines(state_.minorPSLpool_, 5);		
end


