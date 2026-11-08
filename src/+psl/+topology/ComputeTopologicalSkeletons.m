function ComputeTopologicalSkeletons()
%% 【论文 §4.2, Eq.27-31】计算拓扑骨架：对每个退化点求偏应力场一阶导矩阵 M，
%% delta=det(M) 判 trisector(<0)/wedge(>0)；实根三次方程 d·t³+(c+2b)t²+(2a-d)t-c=0
%% 给出骨架分支方向，再从退化点出发沿各方向 Tracing 生成骨架 PSL。
	global state_;
	global state_;
	global state_;
	global state_;
	global state_;
	
	prescribedTracingSche = state_.tracingSche_;
	state_.tracingSche_ = 'Euler';
	numDegPts = numel(state_.degePts_);
	if 0==numDegPts, return; end
	
	%%1. Derivatives of Cartesian Stresses at Degenerate Points w.r.t. Cartesian Coordinates
	for ii=1:numDegPts
		iEle = state_.degePts_(ii).eleIndex;
		iEleType = state_.meshTypeMap_(iEle);
		iPara = state_.degePts_(ii).paraCoord;
		[dNds, dNdt] = psl.mesh.DeShapeFunction(iPara, iEleType);
		switch iEleType
			case 'T3'
				iEleNodes = state_.eNodMat_(iEle,1:3);
				iEleCoords = state_.nodeCoords_(iEleNodes,:);
				[iLocalFrame, ~, t1, t2] = psl.mesh.ComputeLocalFrameAtGivenPosition(iPara, iEleCoords, iEleType);
				if state_.approxiInterp_
					iEleStressTensorLocal = state_.localStressFieldPerEle_{iEle};
				else
					iEleStressTensorGlobal = state_.globalStressFieldPerEle_{iEle};
				end
			case 'Q4'
				iEleNodes = state_.eNodMat_(iEle,1:4);
				iEleCoords = state_.nodeCoords_(iEleNodes,:);
				[iLocalFrame, ~, t1, t2] = psl.mesh.ComputeLocalFrameAtGivenPosition(iPara, iEleCoords, iEleType);
				if state_.approxiInterp_
					iEleStressTensorLocal = state_.localStressFieldPerEle_{iEle};
				else
					iEleStressTensorGlobal = state_.globalStressFieldPerEle_{iEle};
				end				
			case 'T6'
				iEleNodes = state_.eNodMat_(iEle,1:6);
				iEleCoords = state_.nodeCoords_(iEleNodes,:);
				[iLocalFrame, ~, t1, t2] = psl.mesh.ComputeLocalFrameAtGivenPosition(iPara, iEleCoords, iEleType);
				if state_.approxiInterp_
					iEleStressTensorLocal = state_.localStressFieldPerEle_{iEle};
				else
					iEleStressTensorGlobal = state_.globalStressFieldPerEle_{iEle};
				end				
			case 'Q8'
				iEleNodes = state_.eNodMat_(iEle,1:8);
				iEleCoords = state_.nodeCoords_(iEleNodes,:);
				[iLocalFrame, ~, t1, t2] = psl.mesh.ComputeLocalFrameAtGivenPosition(iPara, iEleCoords, iEleType);
				if state_.approxiInterp_
					iEleStressTensorLocal = state_.localStressFieldPerEle_{iEle};
				else
					iEleStressTensorGlobal = state_.globalStressFieldPerEle_{iEle};
				end				
		end
		e1 = iLocalFrame(:,1);
		e2 = iLocalFrame(:,2);
		JsurfaceMapping = [sum(t1(:).*e1) sum(t2(:).*e1); sum(t1(:).*e2) sum(t2(:).*e2)];
		dNdxy = inv(JsurfaceMapping)' * [dNds; dNdt];
		if state_.approxiInterp_
			dStressdxLocal = dNdxy(1,:) * iEleStressTensorLocal;
			dStressdyLocal = dNdxy(2,:) * iEleStressTensorLocal;
			df1dx = (dStressdxLocal(1)-dStressdxLocal(2))/2; a = df1dx;
			df1dy = (dStressdyLocal(1)-dStressdyLocal(2))/2; b = df1dy;
			df2dx = dStressdxLocal(3); c = df2dx;
			df2dy = dStressdyLocal(3); d = df2dy;
		else
			dStressdxGlobal = dNdxy(1,:) * iEleStressTensorGlobal;
			dStressdxLocal = psl.stress.GlobalFrame2Local_StressTensor(dStressdxGlobal, iLocalFrame, 1); %% D_sigma_xx_D_xx, D_sigma_yy_D_xx, D_sigma_xy_D_xx
			dStressdyGlobal = dNdxy(2,:) * iEleStressTensorGlobal;
			dStressdyLocal = psl.stress.GlobalFrame2Local_StressTensor(dStressdyGlobal, iLocalFrame, 1); %% D_sigma_xx_D_yy, D_sigma_yy_D_yy, D_sigma_xy_D_yy
			df1dx = (dStressdxLocal(1)-dStressdxLocal(2))/2; a = df1dx;
			df1dy = (dStressdyLocal(1)-dStressdyLocal(2))/2; b = df1dy;
			df2dx = dStressdxLocal(3); c = df2dx;
			df2dy = dStressdyLocal(3); d = df2dy;
		end
		state_.degePts_(ii).df12dxy = [a b; c d];
		state_.degePts_(ii).delta = a*d - b*c; %% Negative -> Trisector; Positive -> Wedge
		rawRoots = roots([d (c+2*b) (2*a-d) -c]);
		state_.degePts_(ii).tangentList = rawRoots(0==imag(rawRoots));
	end
	
	%%2. Get Topological Skeleton
	for ii=1:numDegPts
		state_.degePts_(ii).majorSkeletons = repmat(state_.degePts_(ii).majorSkeletons, numel(state_.degePts_(ii).tangentList), 1);
		state_.degePts_(ii).minorSkeletons = repmat(state_.degePts_(ii).minorSkeletons, numel(state_.degePts_(ii).tangentList), 1);
		for jj=1:numel(state_.degePts_(ii).tangentList)
			ijSeed = [state_.degePts_(ii).eleIndex state_.degePts_(ii).paraCoord];
			iniDir = [1 state_.degePts_(ii).tangentList(jj)]; iniDir = iniDir/norm(iniDir);
			ijMajorPSL = psl.trace.CreatePrincipalStressLine(ijSeed, 'MAJOR', iniDir);
			ijMinorPSL = psl.trace.CreatePrincipalStressLine(ijSeed, 'MINOR', iniDir);
			state_.degePts_(ii).majorSkeletons(jj) = ijMajorPSL;
			state_.degePts_(ii).minorSkeletons(jj) = ijMinorPSL;	
		end
	end
	state_.tracingSche_ = prescribedTracingSche;
end

