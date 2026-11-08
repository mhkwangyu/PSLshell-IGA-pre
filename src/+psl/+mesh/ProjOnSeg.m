function [p,d2] = ProjOnSeg(P,A,B)
    AB = B - A; t = dot(P-A,AB)/max(dot(AB,AB),eps);
    t  = max(0,min(1,t));
    p  = A + t*AB;
    d2 = sum((P - p).^2);
end

