function coordsOut = GlobalFrame2Local_Coords(coordsIn, R, origin, opt)
%% 【论文 §2.2, Eq.7】全局坐标 → 局部系坐标变换。
	switch opt
		case 1 %%Global -> Local
			coordsLocal3x3 = R' * (coordsIn - origin)';
			coordsLocal = coordsLocal3x3(1:2,:)';
			coordsOut = coordsLocal;
		case 0 %%Local -> Global
			coordsLocal3x3 = [coordsIn, zeros(size(coordsIn,1), 1)]';
			coordsGloabl = origin(:) + R * coordsLocal3x3;
			coordsOut = coordsGloabl';
	end
end

