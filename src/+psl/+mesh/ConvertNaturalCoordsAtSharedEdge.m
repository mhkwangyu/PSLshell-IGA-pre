function e1paras = ConvertNaturalCoordsAtSharedEdge(element0, e0paras, edgeIdLocal0, type0, vtxEdgeGloal0, element, edgeIdLocal1, type1, vtxEdgeGloal1)
%% 【论文 §3.2, 图3】沿共享边搬运自然坐标：把某单元边上一点按相对位置映射到相邻单元对应边。
    xi0  = e0paras(1);  eta0 = e0paras(2);
    s0 = psl.mesh.EdgeProgress(type0, edgeIdLocal0, xi0, eta0);
    if  isequal(vtxEdgeGloal0, vtxEdgeGloal1)
        s1 = s0;            % same local direction
    elseif isequal(vtxEdgeGloal0, fliplr(vtxEdgeGloal1))
        s1 = 1 - s0;        % opposite direction (typical for interior edges)
    else
        error('Shared edge mismatch: different end-node pair.');
    end
    [xi1, eta1] = psl.mesh.NatFromProgress(type1, edgeIdLocal1, s1);
    e1paras = [xi1, eta1];
end

