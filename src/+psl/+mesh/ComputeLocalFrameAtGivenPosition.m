function [R, origin, t1, t2] = ComputeLocalFrameAtGivenPosition(paras, iEleNodes, elementType)
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

