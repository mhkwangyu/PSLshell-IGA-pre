function [alpha0, tVec] = CheckSignedDihedralAngle(e1, e1_edgeID, localFrame1, localFrame2)
%% 【论文 §3.4, Eq.18】有符号二面角 α=atan2(h·(n1×n2), n1·n2)：凸脊>0，凹谷<0。
	global state_;
	global state_;
	
	tarEdgeVec = state_.nodeCoords_(state_.eleStruct_(e1).vtxEdgesGlobal(e1_edgeID,:),:);
	tVec = tarEdgeVec(2,:) - tarEdgeVec(1,:); tVec = tVec / norm(tVec);
	n1 = localFrame1(:,3);
	n2 = localFrame2(:,3);
	
	alpha0 = atan2(dot(tVec, cross(n1,n2)), dot(n1, n2));
end

