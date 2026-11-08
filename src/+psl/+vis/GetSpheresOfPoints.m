function [patchX, patchY, patchZ] = GetSpheresOfPoints(points, sphereRadius)
%% 【论文 图7/9】把点集扩展为球（退化点可视化）。
	numSeedPoints = size(points,1);
	[sphereX,sphereY,sphereZ] = sphere(10);
	sphereX = sphereRadius*sphereX;
	sphereY = sphereRadius*sphereY;
	sphereZ = sphereRadius*sphereZ;
	nn = size(sphereX,1);

	patchX = sphereX; ctrX = points(:,1);
	patchX = repmat(patchX, numSeedPoints, 1); ctrX = repmat(ctrX, 1, nn); ctrX = reshape(ctrX', numel(ctrX), 1);
	patchX = ctrX + patchX;
	
	patchY = sphereY; ctrY = points(:,2);
	patchY = repmat(patchY, numSeedPoints, 1); ctrY = repmat(ctrY, 1, nn); ctrY = reshape(ctrY', numel(ctrY), 1);
	patchY = ctrY + patchY;	
	
	patchZ = sphereZ; ctrZ = points(:,3);
	patchZ = repmat(patchZ, numSeedPoints, 1); ctrZ = repmat(ctrZ, 1, nn); ctrZ = reshape(ctrZ', numel(ctrZ), 1);
	patchZ = ctrZ + patchZ;
end

