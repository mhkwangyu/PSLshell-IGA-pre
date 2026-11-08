function [paras, inside] = NewtonRhapson_LocatingPosition3D(eleNodeCoords, target, iEleType)
	% Project a 3D point 'target' onto an isoparametric shell element
	% (T3, T6, Q4, Q8). Returns natural coords [s t] and 'inside' flag
	% (true if converged and (s,t) lies in the element domain).
	%
	% Dependencies: ShapeFunction([s t], type), DeShapeFunction([s t], type)
	
	target = target(:).';            % 1x3
	maxIts = 30;
	tol_r  = 1e-10;                  % residual tolerance (length units)
	tol_x  = 1e-12;                  % step tolerance in (s,t)
	tol_g  = 1e-12;                  % gradient tolerance
	lambda0 = 0;                     % LM damping (0 = pure GN/Newton)
	project_to_domain = true;
	
	% --- initial guess
	switch iEleType
	case 'T3',  s = 1/3; t = 1/3;
	case 'T6',  s = 1/3; t = 1/3;
	case 'Q4',  s = 0.0; t = 0.0;
	case 'Q8',  s = 0.0; t = 0.0;
	otherwise, error('Unknown iEleType');
	end
	
	for it = 1:maxIts
		% shape functions and tangents
		N = psl.mesh.ShapeFunction([s t], iEleType);                 % 1xMe
		[dNds, dNdt] = psl.mesh.DeShapeFunction([s t], iEleType);    % 1xMe
	
		x   = N    * eleNodeCoords;       % 1x3
		xs  = dNds * eleNodeCoords;       % 1x3  = ∂x/∂s
		xt  = dNdt * eleNodeCoords;       % 1x3  = ∂x/∂t
	
		r   = x - target;                 % 1x3
		rn  = norm(r);
	
		% Converged by residual length?
		if rn <= tol_r, break; end
	
		% Gauss–Newton / LM in parameter space: (H + λI) Δ = -g
		H = [ dot(xs,xs), dot(xs,xt);
			dot(xt,xs), dot(xt,xt) ];
		g = [ dot(xs,r);  dot(xt,r) ];
	
		% Optionally adapt λ when H is near-singular
		lambda = lambda0;
		if rcond(H) < 1e-12
			lambda = max(lambda, 1e-12 * trace(H));
		end
	
		dx = - (H + lambda*eye(2)) \ g;   % 2x1 step in (s,t)
	
		% Backtracking line search on φ = 0.5||r||^2
		phi0  = 0.5*rn*rn;
		alpha = 1.0;
		for bt = 1:8
			s_try = s + alpha*dx(1);
			t_try = t + alpha*dx(2);
	
			if project_to_domain
				switch iEleType
					case {'T3','T6'}
						[s_try, t_try] = psl.mesh.ProjectToTriangle([s_try, t_try], [0 0], [1 0], [0 1]);
					case {'Q4','Q8'}
						s_try = max(-1, min( 1, s_try));
						t_try = max(-1, min( 1, t_try));
					otherwise
						error('Unknown iEleType');
				end
			end
	
			% trial residual
			N_try = psl.mesh.ShapeFunction([s_try t_try], iEleType);
			x_try = N_try * eleNodeCoords;
			r_try = x_try - target;
			phi   = 0.5 * dot(r_try, r_try);
	
			if phi <= phi0 * (1 - 1e-4*alpha)    % Armijo
				s = s_try; t = t_try;
				break;
			else
				alpha = 0.5*alpha;
			end
		end
	
		% Converged by small parameter step or small gradient?
		if norm(alpha*dx) <= tol_x || norm(g) <= tol_g
			break;
		end
	end
	
	paras = [s t];

	% Inside test: reference domain with small slack to accept boundary
	slack = 1e-9;
	switch iEleType
	case {'T3','T6'}
		inside = (s >= -slack) && (t >= -slack) && (s+t <= 1+slack);
	case {'Q4','Q8'}
		inside = (s >= -1-slack) && (s <= 1+slack) && (t >= -1-slack) && (t <= 1+slack);
	otherwise
		inside = false;
	end
	
	% Also require that iterations did not exhaust
	inside = inside && (it < maxIts);

end

