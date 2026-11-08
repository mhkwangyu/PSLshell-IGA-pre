function [paras, isDegePt] = NewtonRhapson_LocatingDegPt(iEle, target, varargin)
%% 【论文 §4.1】阻尼 Newton 求偏应力向量零点（退化点的精确位置）。
	global state_;
	global state_;
	global state_;
	
	target = target(:)';
	
	maxIts = 30;
	tol_r  = 1e-5;                      % residual tolerance (stress units)
	tol_x  = 1e-12;                      % step tolerance in param space
	lambda0 = 0;                         % LM damping (0 = pure Newton)
	project_to_domain = true;
	iEleType = state_.meshTypeMap_(iEle);	
	switch iEleType
		case 'T3'
			natCoordScope = [0 0; 1 0; 0 1];
			if state_.approxiInterp_
				eleStressTensorsLocal = state_.localStressFieldPerEle_{iEle};
			else
				vtxCoords = state_.nodeCoords_(state_.eNodMat_(iEle,1:3),:);
                eleStressTensorsGlobal = state_.globalStressFieldPerEle_{iEle};
			end
		case 'Q4'
			natCoordScope = [-1 -1; 1 -1; 1 1; -1 1];
			if state_.approxiInterp_
				eleStressTensorsLocal = state_.localStressFieldPerEle_{iEle};
			else
				vtxCoords = state_.nodeCoords_(state_.eNodMat_(iEle,1:4),:);
                eleStressTensorsGlobal = state_.globalStressFieldPerEle_{iEle};
			end
		case 'T6'
			natCoordScope = [0 0; 1 0; 0 1; 0.5	0; 0.5 0.5; 0 0.5];
			if 3==nargin
				subT6 = varargin{1};
				switch subT6
					case 'T6_1'
						natCoordScope = [0 0; 0.5 0; 0 0.5];
					case 'T6_2'
						natCoordScope = [0.5 0; 1 0; 0.5 0.5];
					case 'T6_3'
						natCoordScope = [0 0.5; 0.5 0.5; 0 1];
					case 'T6_4'
						natCoordScope = [0.5 0; 0.5 0.5; 0 0.5];
					otherwise
						error('Un-supported Division!');
				end
			end
			if state_.approxiInterp_
				eleStressTensorsLocal = state_.localStressFieldPerEle_{iEle};
			else
				vtxCoords = state_.nodeCoords_(state_.eNodMat_(iEle,1:6),:);
				eleStressTensorsGlobal = state_.globalStressFieldPerEle_{iEle};
			end
		case 'Q8'
			natCoordScope = [-1 -1; 1 -1; 1 1; -1 1; 0 -1; 1 0; 0 1; -1 0];
			if 3==nargin
				subQ8 = varargin{1};
				switch subQ8
					case 'Q8_1'
						natCoordScope = [-1 -1; 0 -1; 0 0; -1 0];
					case 'Q8_2'
						natCoordScope = [0 -1; 1 -1; 1 0; 0 0];
					case 'Q8_3'
						natCoordScope = [0 0; 1 0; 1 1; 0 1];
					case 'Q8_4'
						natCoordScope = [-1 0; 0 0; 0 1; -1 1];
					otherwise
						error('Un-supported Division!');
				end				
			end
			if state_.approxiInterp_
				eleStressTensorsLocal = state_.localStressFieldPerEle_{iEle};
			else
				vtxCoords = state_.nodeCoords_(state_.eNodMat_(iEle,1:8),:);
				eleStressTensorsGlobal = state_.globalStressFieldPerEle_{iEle};
			end
		otherwise
			error('Un-supported Element Type!');
	end
	bBox = [min(natCoordScope,[],1); max(natCoordScope,[],1)];
	ctr = sum(natCoordScope,1)/size(natCoordScope,1);
	s = ctr(1); t = ctr(2);
	
	for it = 1:maxIts
		% Shape functions and first derivatives
		N = psl.mesh.ShapeFunction([s t], iEleType);        % 1xMe
		[dNds, dNdt] = psl.mesh.DeShapeFunction([s t], iEleType); % 1xMe
	
		% q(s,t) and residual r = q - target
		if state_.approxiInterp_
			%% q   = N    * vtxVals;                % 1x2
			q = N * [(eleStressTensorsLocal(:,1)-eleStressTensorsLocal(:,2))/2 eleStressTensorsLocal(:,3)];
		else
			iStressGlobal = N * eleStressTensorsGlobal;
			[iLocalFrame, ~, ~, ~] = psl.mesh.ComputeLocalFrameAtGivenPosition([s t], vtxCoords, iEleType);
			iStressLocal = psl.stress.GlobalFrame2Local_StressTensor(iStressGlobal, iLocalFrame, 1);
			q = [(iStressLocal(1)-iStressLocal(2))/2 iStressLocal(3)];		
		end
		r   = q - target;                    % 1x2
		rn  = norm(r);
	
		% Converged by residual?			
		if rn <= tol_r
			break;
		end

		% Jacobian J = dq/d(s,t) arranged as 2x2:
		% J = [ df1/ds  df1/dt ; df2/ds  df2/dt ]
		if state_.approxiInterp_
			dqs = dNds * [(eleStressTensorsLocal(:,1)-eleStressTensorsLocal(:,2))/2 eleStressTensorsLocal(:,3)];  % 1x2  (df1/ds, df2/ds)
			dqt = dNdt * [(eleStressTensorsLocal(:,1)-eleStressTensorsLocal(:,2))/2 eleStressTensorsLocal(:,3)];  % 1x2  (df1/dt, df2/dt)				
		else
			dqsTmpGlobal = dNds * eleStressTensorsGlobal;
			dqsTmpLocal = psl.stress.GlobalFrame2Local_StressTensor(dqsTmpGlobal, iLocalFrame, 1);
			dqs = [(dqsTmpLocal(1)-dqsTmpLocal(2))/2 dqsTmpLocal(3)];
			dqtTmpGlobal = dNdt * eleStressTensorsGlobal;
			dqtTmpLocal = psl.stress.GlobalFrame2Local_StressTensor(dqtTmpGlobal, iLocalFrame, 1);
			dqt = [(dqtTmpLocal(1)-dqtTmpLocal(2))/2 dqtTmpLocal(3)];			
		end
		J   = [ dqs(1) dqt(1) ; dqs(2) dqt(2) ];
	
		% If J is near singular, add LM damping
		% (you can also inspect det(J) or cond(J) to adapt lambda)
		lambda = lambda0;
		H = J; rhs = -r(:);
		if lambda > 0
			H = (J.'*J + lambda*eye(2));    % LM on normal equations
			rhs = -(J.'*r(:));
		end
	
		% Solve for step (Newton or LM)
		% Prefer the square solve when lambda==0 to avoid normal-equations squaring
		if lambda==0
			% robust 2x2 solve with small Tikhonov if singular
			if rcond(J) < 1e-12
				% fallback to damped normal equations
				Hne = (J.'*J + 1e-12*eye(2));
				dx  = Hne \ (-(J.'*r(:)));
			else
				dx = J \ rhs;               % 2x1
			end
		else
			dx = H \ rhs;
		end
	
		% Backtracking line search to ensure decrease of phi = 0.5 ||r||^2
		phi0 = 0.5*rn*rn;
		alpha = 1.0;
		for bt = 1:8
			s_try = s + alpha*dx(1);
			t_try = t + alpha*dx(2);
	
			% Optional: project to reference domain to avoid wild steps
			if project_to_domain
				if strcmp(iEleType, 'T6') || strcmp(iEleType, 'T3')
					[s_try, t_try] = psl.mesh.ProjectToTriangle([s_try, t_try], natCoordScope(1,:), natCoordScope(2,:), natCoordScope(3,:));
				elseif strcmp(iEleType, 'Q4') || strcmp(iEleType, 'Q8')	
					s_try = max(bBox(1,1),min(bBox(2,1),s_try));
					t_try = max(bBox(1,2),min(bBox(2,2),t_try));
				else
					error('Un-supported Element Type!');
				end
			end
	
			N_try = psl.mesh.ShapeFunction([s_try t_try], iEleType);
			if state_.approxiInterp_
				q_try = N_try * [(eleStressTensorsLocal(:,1)-eleStressTensorsLocal(:,2))/2 eleStressTensorsLocal(:,3)];
			else
				iStressGlobal_try = N_try * eleStressTensorsGlobal;
				[iLocalFrame, ~, ~, ~] = psl.mesh.ComputeLocalFrameAtGivenPosition([s_try t_try], vtxCoords, iEleType);
				iStressLocal = psl.stress.GlobalFrame2Local_StressTensor(iStressGlobal_try, iLocalFrame, 1);
				q_try = [(iStressLocal(1)-iStressLocal(2))/2 iStressLocal(3)];				
			end
			r_try = q_try - target;
			phi   = 0.5*dot(r_try,r_try);
	
			if phi <= phi0 * (1 - 1e-4*alpha)     % Armijo condition
				s = s_try; t = t_try;
				break;
			else
				alpha = 0.5*alpha;
			end
		end
	
		% Converged by step size?
		if norm(alpha*dx) <= tol_x
			break;
		end
    end
	paras  = [s t];
	inside = psl.mesh.CheckWhetherGivenNaturalCoordinatesWithinDomain(paras, iEleType, 1.0e-12);
	isDegePt = inside && it < maxIts;
end

