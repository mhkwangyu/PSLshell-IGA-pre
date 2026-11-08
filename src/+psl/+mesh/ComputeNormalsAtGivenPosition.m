function [faceNormList, tVec1, tVec2] = ComputeNormalsAtGivenPosition(paras, iEleNodes, elementType)
%% 【论文 §2.1】在任一点求法向与两个切向量（供法向可视化/局部系构造使用）。
	[dNdxi, dNdeta] = psl.mesh.DeShapeFunction(paras, elementType);
	%%Tangent Planes at "paras"
	tVec1 = dNdxi * iEleNodes;
	tVec2 = dNdeta * iEleNodes;
	nVec = cross(tVec1, tVec2);
	nVec = nVec ./ vecnorm(nVec,2,2);
	faceNormList = nVec;
end

