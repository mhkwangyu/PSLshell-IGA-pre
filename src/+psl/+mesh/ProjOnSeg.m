function [p,d2] = ProjOnSeg(P,A,B)
%% 【论文 附录】把点正交投影到线段（ProjectToTriangle 的子工具）。
    AB = B - A; t = dot(P-A,AB)/max(dot(AB,AB),eps);
    t  = max(0,min(1,t));
    p  = A + t*AB;
    d2 = sum((P - p).^2);
end

