function [targetDirection, terminationCond] = BidirectionalFeatureProcessing_Advanced(d0Local, v1Local, localFrame0, iLocalFrame, eRef, refEdgeID)
%% 【论文 §3.4, Eq.17-21】方向正则（跨单元/折痕情形）：含 30° 近共面快路径(跳过旋转)
%% 与 Rodrigues 旋转 W(h,α)=I+sinα·H+(1-cosα)H² 把上一单元方向"掰"到当前切平面再比较。
	terminationCond = 0;
	
	n0 = localFrame0(:,3);
	n1 = iLocalFrame(:,3);
	[alpha0, tVec] = psl.trace.CheckSignedDihedralAngle(eRef, refEdgeID, localFrame0, iLocalFrame);
	D0Global = psl.stress.GlobalFrame2Local_Vecs(d0Local, localFrame0, 0);
	V1Global = psl.stress.GlobalFrame2Local_Vecs(v1Local, iLocalFrame, 0);
	if abs(alpha0) <= pi/6
		angle1 = acos(V1Global*D0Global(:));
		angle2 = acos(-V1Global*D0Global(:));		
	else
		% turningAng = alpha0/pi*180
		T = [0 -tVec(3) tVec(2); tVec(3) 0 -tVec(1); -tVec(2) tVec(1) 0];
		W = eye(3) + sin(alpha0)*T + (1-cos(alpha0))*(T*T);
		
		D0W = W*D0Global(:);
		%%Numerical instability
		D0W = D0W - (dot(D0W, n0))* n1; D0W = D0W/norm(D0W);
		angle1 = acos(V1Global*D0W);
		angle2 = acos(-V1Global*D0W);	
	end
	
	if angle1 < angle2
		targetDirection = v1Local;
		if angle1 > 70/180*pi, terminationCond = 1; end
	else
		targetDirection = -v1Local;
		if angle2 > 70/180*pi, terminationCond = 1; end
	end	
end

