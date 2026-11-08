function paraCoordIncrement = ComputeIncrementOfNaturalCoordFromIncrementOfLocalCoord(localCoordIncrement, localFrame, t1, t2)
	e1 = localFrame(:,1);
	e2 = localFrame(:,2);
	JsurfaceMapping = [sum(t1.*e1) sum(t2.*e1); sum(t1.*e2) sum(t2.*e2)];
	paraCoordIncrement = JsurfaceMapping \ localCoordIncrement(:);
	paraCoordIncrement = paraCoordIncrement';
end

