function opt = DegenrationMeasure_BernsteinBoundingQuad(eleStress)
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

