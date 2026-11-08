function psList = ComputePrincipalStressLocalFrame(stressTensors)
	numStressTensors = size(stressTensors,1);
	switch size(stressTensors,2)
		case 3 %%Local Frame
			%% Per-row: sigma_xx, sigma_yy, sigma_xy
			psList = zeros(numStressTensors,6);
			for ii=1:numStressTensors
				iStressTensor = stressTensors(ii,:);
				iStressTensor = iStressTensor([1 3; 3 2]);
				[eigenVec, eigenVal] = eig(iStressTensor);
				iPS = [eigenVal(1,1); eigenVec(:,1); eigenVal(2,2); eigenVec(:,2)]';
				psList(ii,:) = iPS;		
			end		
		case 6
			%% Per-row: sigma_xx, sigma_yy, sigma_zz, sigma_yz, sigma_zx, sigma_xy
			psList = zeros(numStressTensors,12);
			for ii=1:numStressTensors
				iStressTensor = stressTensors(ii,:);
				iStressTensor = iStressTensor([1 6 5; 6 2 4; 5 4 3]);
				[eigenVec, eigenVal] = eig(iStressTensor);
				iPS = [eigenVal(1,1); eigenVec(:,1); eigenVal(2,2); eigenVec(:,2); eigenVal(3,3); eigenVec(:,3)]';
				psList(ii,:) = iPS;		
			end		
	end
end

