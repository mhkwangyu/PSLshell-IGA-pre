function [R, origin, t1, t2] = ComputeLocalFrameAtGivenPosition(paras, iEleNodes, elementType)
%% 【论文 §2.1, Eq.2-6】在任一点 (ξ,η) 构造单元局部正交系 R = [e1 e2 e3]。
%% t1=∂P/∂ξ, t2=∂P/∂η 为切向量；法向 e3=t1×t2/|t1×t2|；
%% 用参考向量 r（默认 [1,0,0]，与法向近平行时退回 [0,0,1]）投影到切平面得 e1，
%% 右手法则 e2=e3×e1。离散化关键：r 的约定决定了局部主方向角，读外部应力须一致。
	global state_;
	N = psl.mesh.ShapeFunction(paras, elementType);
	[dNdxi, dNdeta] = psl.mesh.DeShapeFunction(paras, elementType);
	%%Tangent Planes at "paras"
	t1 = dNdxi * iEleNodes;
	t2 = dNdeta * iEleNodes;
	origin = N*iEleNodes;
	nVec = cross(t1, t2);
	e3 = nVec ./ vecnorm(nVec,2,2);
	rVec = state_.refVec_;
	tVec = rVec - (dot(rVec, e3))*e3;
	if norm(tVec) < state_.tolRefVecFallback_
		rVec = state_.refVecFallback_;
		tVec = rVec - (dot(rVec, e3))*e3;
		if norm(tVec) < state_.tolRefVecFallback_
			error('Reference directions are parallel to normal; provide a custom ref.');
		end				
	end
	e1 = tVec / norm(tVec);
	e2 = cross(e3, e1);
	R = [e1(:), e2(:), e3(:)];
end

