function parasOut = AvoidExactLocationAtVertexOrEdge4Robustness(parasIn, eleType, safetyScaling)
%% 【论文 §3.2】把恰好落在顶点/边上的自然坐标微调入内部，避免跨单元判定时的退化歧义（鲁棒性补丁）。
	xi = parasIn(1);
	eta = parasIn(2);
	tolEff = safetyScaling;
	if strcmp(eleType, 'T3') || strcmp(eleType, 'T6')
		if abs(xi)<tolEff
			xi = safetyScaling;
		elseif abs(xi-1)<tolEff
			xi = 1 - safetyScaling;
		end
		if abs(eta)<tolEff
			eta = safetyScaling;
		elseif abs(eta-1)<tolEff
			eta = 1 - safetyScaling;
		end
		if abs(1-xi-eta)<tolEff
			xi = xi*(1-safetyScaling);
			eta = eta*(1-safetyScaling);
		end			
	elseif strcmp(eleType, 'Q4') || strcmp(eleType, 'Q8')
		if xi>-1-tolEff &&  xi<-1+tolEff
			xi = -1+safetyScaling;
		elseif xi>1-tolEff && xi<1+tolEff
			xi = 1-safetyScaling;
		end
		if eta>-1-tolEff &&  eta<-1+tolEff
			eta = -1+safetyScaling;
		elseif eta>1-tolEff && eta<1+tolEff
			eta = 1-safetyScaling;
		end			
	else
		error('Un-supported Element Type!');
	end
	parasOut = [xi eta];
end

