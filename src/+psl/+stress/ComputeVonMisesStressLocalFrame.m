function iVonMisesStress = ComputeVonMisesStressLocalFrame(iStressTensor)
%% 【论文 图1】von Mises 等效应力（供着色可视化）。
	switch size(iStressTensor,2)
		case 3 %%Local Frame
			%% Per-row: sigma_xx, sigma_yy, sigma_xy
			iVonMisesStress = sqrt(iStressTensor(:,1).^2 + iStressTensor(:,2).^2 - iStressTensor(:,1).*iStressTensor(:,2) + 3*iStressTensor(:,3).^2);	
		case 6
			%% Per-row: sigma_xx, sigma_yy, sigma_zz, sigma_yz, sigma_zx, sigma_xy
			iVonMisesStress = sqrt(0.5*((iStressTensor(:,1)-iStressTensor(:,2)).^2 + (iStressTensor(:,2)-iStressTensor(:,3)).^2 + (iStressTensor(:,3)...
					-iStressTensor(:,1)).^2 ) + 3*( iStressTensor(:,6).^2 + iStressTensor(:,4).^2 + iStressTensor(:,5).^2 ));			
	end
end

