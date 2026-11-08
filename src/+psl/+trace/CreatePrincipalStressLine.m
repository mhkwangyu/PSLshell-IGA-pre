function iPSL = CreatePrincipalStressLine(seed, tracingType, varargin)
	iPSL = psl.trace.PrincipalStressLineStruct();
	switch tracingType
		case 'MAJOR', psDir = [5 6];
		case 'MINOR', psDir = [2 3];
	end
	%%1. prepare for tracing
	[seed, phyCoord0, ~, localFrame0, t1, t2, localStressTensor0, localPrincipalStress0, localVonMisesStress0, opt] = psl.trace.PreparingForTracing(seed);
	if ~opt, return; end
	if 3==nargin
		localPrincipalStress0(psDir) = varargin{1}; %%Prescribed Principal Stress Direction at Degenerate Point
	end
	
	%%2. tracing PSL
	PSLphyCoordList = phyCoord0;
	PSLeleIndexList = seed(1);
	PSLparaCoordList = seed(2:3);
	PSLocalFrameList = localFrame0;
	PSLocalStressTensorList = localStressTensor0;
	PSLocalPrincipalStressList = localPrincipalStress0;
	PSLocalVonMisesStressList = localVonMisesStress0;
	
	e0 = PSLeleIndexList; para0 = PSLparaCoordList;
	v0 = localPrincipalStress0(1,psDir);	
	%%2.1 along first direction (v0)
	[phyCoordList, eleIndexList, paraCoordList, localFrameList, localStressTensorList, localPrincipalStressList, localVonMisesStressList] = ...
		psl.trace.Tracing(e0, para0, localFrame0, t1, t2, v0, psDir);
	numNewlyGeneratedIntergPts = numel(eleIndexList);
	PSLphyCoordList = [PSLphyCoordList; phyCoordList];
	PSLeleIndexList = [PSLeleIndexList; eleIndexList];
	PSLparaCoordList = [PSLparaCoordList; paraCoordList];
	PSLocalFrameList(:,:,end+1:end+numNewlyGeneratedIntergPts) = localFrameList;
	PSLocalStressTensorList = [PSLocalStressTensorList; localStressTensorList];
	PSLocalPrincipalStressList = [PSLocalPrincipalStressList; localPrincipalStressList];	
	PSLocalVonMisesStressList = [PSLocalVonMisesStressList; localVonMisesStressList];
	%%2.2 along second direction (-v0)
	[phyCoordList, eleIndexList, paraCoordList, localFrameList, localStressTensorList, localPrincipalStressList, localVonMisesStressList] = ...
		psl.trace.Tracing(e0, para0, localFrame0, t1, t2, -v0, psDir);
	numNewlyGeneratedIntergPts = numel(eleIndexList);
	if numNewlyGeneratedIntergPts > 1
		phyCoordList = flip(phyCoordList);
		eleIndexList = flip(eleIndexList);
		paraCoordList = flip(paraCoordList);
		localFrameList = flip(localFrameList,3);
		localStressTensorList = flip(localStressTensorList);
		localPrincipalStressList = flip(localPrincipalStressList);
		localVonMisesStressList = flip(localVonMisesStressList);
	end
	PSLphyCoordList = [phyCoordList; PSLphyCoordList];
	PSLeleIndexList = [eleIndexList; PSLeleIndexList];
	PSLparaCoordList = [paraCoordList; PSLparaCoordList];
	localFrameList(:,:,end+1:end+size(PSLocalFrameList,3)) = PSLocalFrameList; PSLocalFrameList = localFrameList;
	PSLocalStressTensorList = [localStressTensorList; PSLocalStressTensorList];
	PSLocalPrincipalStressList = [localPrincipalStressList; PSLocalPrincipalStressList];	
	PSLocalVonMisesStressList = [localVonMisesStressList; PSLocalVonMisesStressList];
	
	%%2.3 finish Tracing the current major PSL	
	iPSL.midPointPosition = size(phyCoordList,1)+1;
	iPSL.numIntergPts = size(PSLphyCoordList,1);
	iPSL.phyCoordList = PSLphyCoordList;
	iPSL.eleIndexList = PSLeleIndexList;
	iPSL.paraCoordList = PSLparaCoordList;
	iPSL.localFrames = PSLocalFrameList;
	iPSL.localStressTensorList = PSLocalStressTensorList;	
	iPSL.localPrincipalStressList = PSLocalPrincipalStressList;	
	iPSL.localVonMisesStressList = PSLocalVonMisesStressList;	
end

