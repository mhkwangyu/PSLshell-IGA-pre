function oPSLs = CompactStreamlines(iPSLs, truncatedThreshold)
%% 【论文 §5】抽稀：过滤积分点数过少(<=truncatedThreshold)的碎短轨迹。
	tarIndice = [];
	for ii=1:numel(iPSLs)
		if iPSLs(ii).numIntergPts > truncatedThreshold
			tarIndice(end+1,1) = ii;
		end
	end
	oPSLs = iPSLs(tarIndice);
	if isempty(oPSLs), oPSLs = []; end
end

