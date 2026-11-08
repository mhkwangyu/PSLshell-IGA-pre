function [v1, terminationCond] = BidirectionalFeatureProcessing(v0, v1Potential, localFrame0, localFrame1)
	global state_;
	terminationCond = 0;
	
	v0Global = psl.stress.GlobalFrame2Local_Vecs(v0, localFrame0, 0);
	v1Potentialglobal = psl.stress.GlobalFrame2Local_Vecs(v1Potential, localFrame1, 0);	
	
	angle1 = acos(v0Global*v1Potentialglobal');
	angle2 = acos(-v0Global*v1Potentialglobal');
	if angle1 < angle2
		v1 = v1Potential;
		if angle1 > state_.permittedMaxAdjacentTangentAngleDeviation_/180*pi, terminationCond = 1; end
	else
		v1 = -v1Potential;
		if angle2 > state_.permittedMaxAdjacentTangentAngleDeviation_/180*pi, terminationCond = 1; end
	end
end

