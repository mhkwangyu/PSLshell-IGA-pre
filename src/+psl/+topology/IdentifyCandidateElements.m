function IdentifyCandidateElements()
%% 【论文 §4.3, Eq.35-39】候选单元预筛：符号一致性检查 + Bernstein-Bézier 区间界，
%% 严格排除不可能含退化点的单元（对任意阶次成立，大幅缩小搜索范围）。
	global state_;
	global state_;
	global state_;
	
	excludedElementMap = true(state_.numEles_,1);
	
	for ii=1:state_.numEles_
		if state_.voidEleMap_(ii), continue; end
		eleStress = state_.localStressFieldPerEle_{ii};
		switch state_.meshTypeMap_(ii)
			case {'T3', 'Q4', 'T6'}
				opt = psl.topology.DegenrationMeasure_SignConsistency(eleStress);
			case 'Q8'
				stressAtCtr = psl.mesh.ShapeFunction([0 0], 'Q8') * eleStress;		
				opt = psl.topology.DegenrationMeasure_BernsteinBoundingQuad([eleStress; stressAtCtr]);
		end
		excludedElementMap(ii) = opt;
	end
	state_.candidateElementsIncDegePts_ = find(false==excludedElementMap);
	state_.candidateElementsIncDegePts_ = setdiff(state_.candidateElementsIncDegePts_, state_.boundaryElements_);
end

