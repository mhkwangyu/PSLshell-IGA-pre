function vecsOut = GlobalFrame2Local_Vecs(vecsIn, R, opt)
%% 【论文 §2.2, Eq.8】全局向量 → 局部系向量（方向对比都在全局系做，见 Eq.17）。
	switch opt
		case 1 %%Global -> Local
			vecsLocal3x3 = R' * vecsIn';
			vecsLocal = vecsLocal3x3(1:2,:)';
			vecsOut = vecsLocal;
		case 0 %%Local -> Global
			vecsLocal3x3 = [vecsIn, zeros(size(vecsIn,1), 1)]';
			vecsGlobal = (R * vecsLocal3x3)';
			vecsOut = vecsGlobal;
	end
end

