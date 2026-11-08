function [potentialDisList, potentialPosList, potentialPosListPara] = GetDisListOfPointList2Curve(srcPoints, tarCurve, tarCurvePara)
	disT = psl.mesh.DistanceMap2PtCloud(srcPoints(:,end-2:end), tarCurve(:,end-2:end));
	[minVal, minValPos] = min(disT,[],1);
	potentialPosList = tarCurve(minValPos,:);
	potentialPosListPara = tarCurvePara(minValPos,:);
	potentialDisList = minVal(:);
end

