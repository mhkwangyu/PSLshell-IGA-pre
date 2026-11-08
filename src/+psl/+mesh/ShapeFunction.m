function N = ShapeFunction(paras, elementType)
	numSamps = size(paras,1);
	s = paras(:,1);
	t = paras(:,2);
	switch elementType
		case 'T3'
			N = zeros(numSamps,3);
			N(:,1) = 1-s-t;
			N(:,2) = s;
			N(:,3) = t;				
		case 'T6'
			N = zeros(numSamps,6);
			N(:,1) = (1-s-t).*(2*(1-s-t)-1);
			N(:,2) = s.*(2*s-1);
			N(:,3) = t.*(2*t-1);
			N(:,4) = 4*s.*(1-s-t);
			N(:,5) = 4*s.*t;
			N(:,6) = 4*t.*(1-s-t);			
		case 'Q4'
			N = zeros(numSamps,4);
			N(:,1) = 0.25*(1-s).*(1-t);
			N(:,2) = 0.25*(1+s).*(1-t);
			N(:,3) = 0.25*(1+s).*(1+t);
			N(:,4) = 0.25*(1-s).*(1+t);			
		case 'Q8'
			N = zeros(numSamps,8);
			N(:,1) = 0.25*(1-s).*(1-t).*(-s-t-1);
			N(:,2) = 0.25*(1+s).*(1-t).*(s-t-1);
			N(:,3) = 0.25*(1+s).*(1+t).*(s+t-1);
			N(:,4) = 0.25*(1-s).*(1+t).*(-s+t-1);
			N(:,5) = 0.5*(1-s.^2).*(1-t);
			N(:,6) = 0.5*(1+s).*(1-t.^2);
			N(:,7) = 0.5*(1-s.^2).*(1+t);
			N(:,8) = 0.5*(1-s).*(1-t.^2);		
		otherwise
			error('Un-supported Element Type!');
	end
end

