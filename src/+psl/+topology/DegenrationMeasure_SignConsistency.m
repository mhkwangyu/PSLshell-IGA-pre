function opt = DegenrationMeasure_SignConsistency(eleStress)
	f1 = (eleStress(:,1)-eleStress(:,2))/2;
	f2 = eleStress(:,3);
	discriminantf1 = (min(f1) > 0) || (max(f1) < 0);
	discriminantf2 = (min(f2) > 0) || (max(f2) < 0);
	opt = (discriminantf1 || discriminantf2);
end

