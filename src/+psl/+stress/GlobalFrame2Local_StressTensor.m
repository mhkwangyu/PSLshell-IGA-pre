function stressOut = GlobalFrame2Local_StressTensor(stressIn, R, opt)
%% 【论文 §2.2, Eq.9-10】全局系应力张量 → 局部系（面内）应力。opt 控制是否做三维嵌入。
	%% sigma_xx, sigma_yy, sigma_zz, sigma_yz, sigma_zx, sigma_xy (global)
	numComps = size(R,3);
	if numComps~=size(stressIn,1)
		error('Un-matched Dimensions!');
	end
	switch opt
		case 1 %%Global -> Local
			stressOut = zeros(numComps,3);
			for ii=1:numComps
				iR = R(:,:,ii);
				iStressIn = stressIn(ii,:);
				iStressLocal3x3 = iR' * iStressIn([1 6 5; 6 2 4; 5 4 3]) * iR;
				stressOut(ii,:) = iStressLocal3x3([1 5 2]);
			end
		case 0 %%Local -> Global
			stressOut = zeros(numComps,6);
			for ii=1:numComps
				iR = R(:,:,ii);
				iStressIn = stressIn(ii,:);
				iStressLocal3x3 = zeros(3,3);
				iStressLocal3x3(1,1:2) = iStressIn([1 3]);
				iStressLocal3x3(2,1:2) = iStressIn([3 2]);
				iStressGlobal3x3 = iR * iStressLocal3x3 * iR';
				stressOut(ii,:) = iStressGlobal3x3([1 5 9 6 3 2]);
			end
	end
end

