function opt = DegenrationMeasure_SignConsistency(eleStress)
%% 【论文 §4.3】退化点预筛判据1：节点上 f1(或 f2) 符号一致则单元必无退化点（T3/Q4/T6 有效）。
	f1 = (eleStress(:,1)-eleStress(:,2))/2;
	f2 = eleStress(:,3);
	discriminantf1 = (min(f1) > 0) || (max(f1) < 0);
	discriminantf2 = (min(f2) > 0) || (max(f2) < 0);
	opt = (discriminantf1 || discriminantf2);
end

