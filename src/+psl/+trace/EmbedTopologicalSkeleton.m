function EmbedTopologicalSkeleton()
	global state_;
	global state_;
	global state_;
	global state_;
	global state_;
	global state_;
	global state_;
	
	%%Move Topological Skeleton to Major and Minor PSL Pools
	if ~isempty(state_.degePts_)
		for ii=1:numel(state_.degePts_)
			for jj=1:numel(state_.degePts_(ii).majorSkeletons)
				state_.majorPSLpool_(end+1,1) = state_.degePts_(ii).majorSkeletons(jj);
				state_.majorCoordList_(end+1:end+state_.degePts_(ii).majorSkeletons(jj).numIntergPts,:) = state_.degePts_(ii).majorSkeletons(jj).phyCoordList;
			end
			for jj=1:numel(state_.degePts_(ii).minorSkeletons)
				state_.minorPSLpool_(end+1,1) = state_.degePts_(ii).minorSkeletons(jj);
				state_.minorCoordList_(end+1:end+state_.degePts_(ii).minorSkeletons(jj).numIntergPts,:) = state_.degePts_(ii).minorSkeletons(jj).phyCoordList;
			end			
		end
	end
	numMajorPSLs = numel(state_.majorPSLpool_);
	for ii=1:numMajorPSLs
		majorPSL = state_.majorPSLpool_(ii);
		if majorPSL.numIntergPts>0					
			sppsEmptyMajorValence = find(0==state_.seedPointsValence_(:,1));
            if ~isempty(sppsEmptyMajorValence)
				[potentialDisListMajor, potentialPosListMajor, potentialPosListMajorPara] = psl.trace.GetDisListOfPointList2Curve(...	
					state_.seedPointsRef_(sppsEmptyMajorValence,:), [majorPSL.eleIndexList majorPSL.phyCoordList], [majorPSL.eleIndexList majorPSL.paraCoordList]);
				potentialSolidSppsMajor = find(potentialDisListMajor<=state_.mergingThreshold_);
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
	end
	numMinorPSLs = numel(state_.minorPSLpool_);
	for ii=1:numMinorPSLs
		minorPSL = state_.minorPSLpool_(ii);
		if minorPSL.numIntergPts>0	
			sppsEmptyMinorValence = find(0==state_.seedPointsValence_(:,2));
            if ~isempty(sppsEmptyMinorValence)
				[potentialDisListMinor, potentialPosListMinor, potentialPosListMinorPara] = psl.trace.GetDisListOfPointList2Curve(...	
					state_.seedPointsRef_(sppsEmptyMinorValence,:), [minorPSL.eleIndexList minorPSL.phyCoordList], [minorPSL.eleIndexList minorPSL.paraCoordList]);
				potentialSolidSppsMinor = find(potentialDisListMinor<=state_.mergingThreshold_);
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
	end
end

