function [potentialDisList, potentialPosList, potentialPosListPara] = GetDisListOfPointList2Curve(srcPoints, tarCurve, tarCurvePara)
%% 【论文 §5】种子点集合到某条轨迹的最近距离（供合并判定）。
	disT = psl.mesh.DistanceMap2PtCloud(srcPoints(:,end-2:end), tarCurve(:,end-2:end));
	[minVal, minValPos] = min(disT,[],1);
	potentialPosList = tarCurve(minValPos,:);
	potentialPosListPara = tarCurvePara(minValPos,:);
	potentialDisList = minVal(:);
end

