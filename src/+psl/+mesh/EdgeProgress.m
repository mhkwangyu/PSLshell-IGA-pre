function s = EdgeProgress(t, edgeId, xi, eta)
	if 'T3'==t || 'T6'==t
        switch edgeId
            case 1, s = xi;          % along base 1->2
            case 2, s = eta;         % along hypotenuse 2->3
            case 3, s = 1 - eta;     % along left 3->1
            otherwise, error('tri edgeId must be 1..3');
        end	
	elseif 'Q4'==t || 'Q8'==t
       switch edgeId
           case 1, s = (xi  + 1)/2; % bottom
           case 2, s = (eta + 1)/2; % right
           case 3, s = (1 - xi)/2;  % top
           case 4, s = (1 - eta)/2; % left
           otherwise, error('quad edgeId must be 1..4');
       end
	else
		error('Un-supported Element Type!');
	end
end

