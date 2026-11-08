function [sp,tp] = ProjectToTriangle(st, A, B, C)
% Orthogonal projection of point st=[s t] onto triangle ABC in R^2
    P = st(:); A2=A(:); B2=B(:); C2=C(:);
    v0 = B2 - A2; v1 = C2 - A2; v2 = P - A2;
    M  = [v0 v1];                             % 2x2
    uv = M \ v2;  u = uv(1); v = uv(2);
    if u >= 0 && v >= 0 && u+v <= 1
        Q = A2 + M*[u; v];
        sp = Q(1); tp = Q(2); return;
    end
    [pAB,dAB] = psl.mesh.ProjOnSeg(P, A2, B2);
    [pAC,dAC] = psl.mesh.ProjOnSeg(P, A2, C2);
    [pBC,dBC] = psl.mesh.ProjOnSeg(P, B2, C2);
    [~,idx] = min([dAB,dAC,dBC]);
    if idx==1, Q=pAB; elseif idx==2, Q=pAC; else, Q=pBC; end
    sp = Q(1); tp = Q(2);
end

