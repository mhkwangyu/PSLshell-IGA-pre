function [xi,eta] = NatFromProgress(t, edgeId, s)
%% 【论文 §3.2】由边参数 t 反解出该边上的自然坐标 (ξ,η)（EdgeProgress 的逆）。
    s = max(0, min(1, s));  % tiny clamp
	if 'T3'==t || 'T6'==t
        switch edgeId
            case 1, xi = s;     eta = 0;
            case 2, xi = 1 - s; eta = s;
            case 3, xi = 0;     eta = 1 - s;
        end	
	elseif 'Q4'==t || 'Q8'==t
        switch edgeId
            case 1, xi = -1 + 2*s; eta = -1;
            case 2, xi =  1;      eta = -1 + 2*s;
            case 3, xi =  1 - 2*s;eta =  1;
            case 4, xi = -1;      eta =  1 - 2*s;
        end	
	else
		error('Un-supported Element Type!');
	end
end

