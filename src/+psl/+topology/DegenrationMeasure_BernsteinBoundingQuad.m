function opt = DegenrationMeasure_BernsteinBoundingQuad(eleStress)
%% 【论文 §4.3, Eq.35-39, 附录A】退化点预筛判据2：Bernstein-Bézier 凸包区间界，
%% 系数经 C·S·C^T 变换，[minB,maxB] 严格界定函数范围，可严格排除（对 Q8 亦有效）。
	f1 = (eleStress(:,1)-eleStress(:,2))/2;
	f2 = eleStress(:,3);	
	reOrdering = [1 8 4 5 9 7 2 6 3]';
	f1 = f1(reOrdering);
	f2 = f2(reOrdering);
	S1 = reshape(f1, 3, 3)';
	S2 = reshape(f2, 3, 3)';

	C = [1 0 0; -0.5 2 -0.5; 0 0 1];
	B1 = C * S1 * C';
	B2 = C * S2 * C';

	f1min = min(B1(:)); f1max = max(B1(:));
	f2min = min(B2(:)); f2max = max(B2(:));

	discriminantf1 = (f1min > 0) || (f1max < 0);
	discriminantf2 = (f2min > 0) || (f2max < 0);

	opt = (discriminantf1 || discriminantf2);
end

