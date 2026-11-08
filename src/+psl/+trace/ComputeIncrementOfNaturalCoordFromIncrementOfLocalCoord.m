function paraCoordIncrement = ComputeIncrementOfNaturalCoordFromIncrementOfLocalCoord(localCoordIncrement, localFrame, t1, t2)
%% 【论文 §3.2, Eq.15-16】自然坐标增量求解 —— 全文"心脏"一步。
%% 把"该走多远"（局部系位置增量 localCoordIncrement 有物理意义）翻译成
%% 自然坐标增量 Δ(ξ,η)。组装面 Jacobian J = [e1·t1 e1·t2; e2·t1 e2·t2]，
%% 求 Δ(ξ,η) = J^{-1} · Δx。关键收益：新点始终定义在自然坐标里，
%% 判断是否越界退化为"与标准等参单元比大小"，无需 Newton-Raphson 反解位置。
	e1 = localFrame(:,1);
	e2 = localFrame(:,2);
	JsurfaceMapping = [sum(t1.*e1) sum(t2.*e1); sum(t1.*e2) sum(t2.*e2)];
	paraCoordIncrement = JsurfaceMapping \ localCoordIncrement(:);
	paraCoordIncrement = paraCoordIncrement';
end

