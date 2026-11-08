function iniSeedPoints = SetupSeeds(seedSparsityCtrl)
%% 【论文 §5】初始化种子点：按 seedSparsityCtrl 稀疏度取单元中心作为种子。
	global state_;
	global state_;
	iniSeedPoints = zeros(state_.numEles_, 3);
	for ii=1:state_.numEles_
		iEleType = state_.meshTypeMap_(ii);
		switch iEleType
			case {'T3', 'T6'}
				iniSeedPoints(ii,:) = [ii 1/3 1/3];
			case {'Q4', 'Q8'}
				iniSeedPoints(ii,:) = [ii 0 0];
		end
	end
	iniSeedPoints = iniSeedPoints(1:seedSparsityCtrl:end,:);
	iniSeedPoints(find(state_.voidEleMap_),:) = [];
end

