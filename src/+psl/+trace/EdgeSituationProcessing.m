function [e0, e0Type, paraCoord1, e0_edgeIDlocal, optAtBoundary, paraCoord1Fallback] = EdgeSituationProcessing(e0, paraCoord0, paraCoord1, e0Type)
	global state_;
	tolBoundaryCloseness = 1.0e-2;
	optAtBoundary = false;
	%%Get Intersection
	[e0_edgeIDlocal, paraCoord1Fallback, stateIntersection] = psl.mesh.DetectIntersectedEdgeInNaturalFrame(paraCoord0, paraCoord1, e0Type);
	if ~stateIntersection
		warning('No Intersection Found!')
		paraCoord0
		paraCoord1
	end
	e1 = state_.eleStruct_(e0).edge2nextEle(e0_edgeIDlocal);
	if 0==e1%%paraCoord1 is not in the domain 
		%%Endpoint treatment when reaching boundary 
		if norm(paraCoord0-paraCoord1Fallback) > tolBoundaryCloseness
			paraCoord1 = paraCoord1Fallback;
			reachingBoundary = true;
		else %%Already at the boundary
			optAtBoundary = true;
			%break;
		end
	elseif state_.voidEleMap_(e1) %%enter into void element
		optAtBoundary = true;
	else %%paraCoord1 is not in e0 but still in the domain, specificly in e1
		%%Shift computing stencils (natural coordinates) to next element (e1)
		%%Convert Natural Coordinates (NC) at Shared Edge of 2 Adjacent Elements
		e0_sharedEdge_NatCoord = paraCoord1Fallback;
		e1_edgeIDlocal = state_.eleStruct_(e0).edgeIDsOfNextEle(e0_edgeIDlocal);
		e1_sharedEdge_NatCoord = psl.mesh.ConvertNaturalCoordsAtSharedEdge(e0, e0_sharedEdge_NatCoord, e0_edgeIDlocal, e0Type, ...
			state_.eleStruct_(e0).vtxEdgesGlobal(e0_edgeIDlocal,:), e1, e1_edgeIDlocal, state_.meshTypeMap_(e1), ...
				state_.eleStruct_(e1).vtxEdgesGlobal(e1_edgeIDlocal,:));
		%%***Maybe Problematic for Sharp Edge***
		e0 = e1;
		e0Type = state_.meshTypeMap_(e0);
		paraCoord1 = e1_sharedEdge_NatCoord;			
	end	
end	

