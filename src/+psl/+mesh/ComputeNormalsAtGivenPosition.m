function [faceNormList, tVec1, tVec2] = ComputeNormalsAtGivenPosition(paras, iEleNodes, elementType)
	[dNdxi, dNdeta] = psl.mesh.DeShapeFunction(paras, elementType);
	%%Tangent Planes at "paras"
	tVec1 = dNdxi * iEleNodes;
	tVec2 = dNdeta * iEleNodes;
	nVec = cross(tVec1, tVec2);
	nVec = nVec ./ vecnorm(nVec,2,2);
	faceNormList = nVec;
end

