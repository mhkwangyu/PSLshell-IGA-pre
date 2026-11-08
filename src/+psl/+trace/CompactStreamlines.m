function oPSLs = CompactStreamlines(iPSLs, truncatedThreshold)
	tarIndice = [];
	for ii=1:numel(iPSLs)
		if iPSLs(ii).numIntergPts > truncatedThreshold
			tarIndice(end+1,1) = ii;
		end
	end
	oPSLs = iPSLs(tarIndice);
	if isempty(oPSLs), oPSLs = []; end
end

