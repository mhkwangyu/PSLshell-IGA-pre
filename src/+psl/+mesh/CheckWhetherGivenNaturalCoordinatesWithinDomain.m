function inside = CheckWhetherGivenNaturalCoordinatesWithinDomain(paras, eleType, varargin)
	inside  = 0;
	xi = paras(1); eta = paras(2);
	if ~(isfinite(xi) && isfinite(eta))
		inside = false;
		error('Infinite Natural Coordinates!');
	end
	
	if 3==nargin
		tolEff = varargin{1};
	else
		tolEff = 0;
	end
	%tolEff = 50 * eps(scale);
	
	if strcmp(eleType, 'T3') || strcmp(eleType, 'T6')
		l1 = 1 - xi - eta;
		l2 = xi;
		l3 = eta;
		inside = (l1 >= -tolEff) & (l2 >= -tolEff) & (l3 >= -tolEff);	
	elseif strcmp(eleType, 'Q4') || strcmp(eleType, 'Q8')
		inside = (xi >= -1 - tolEff) && (xi <= 1 + tolEff) && (eta >= -1 - tolEff) && (eta <= 1 + tolEff);
	else
		error('Un-supported Element Type!');
	end
end

