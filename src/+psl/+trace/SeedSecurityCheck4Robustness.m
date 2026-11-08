function [e0out, paraCoord0out, localFrame0out, t1out, t2out, v0out] = SeedSecurityCheck4Robustness(e0in, paraCoord0in, localFrame0in, t1in, t2in, v0in)
%% 【论文 §3.2】种子鲁棒性检查：把种子归一化到合法单元内、法向一致、边点微调。
	%% This function is introduced to counteract the situation where the seed point is exactly located at the element 
	%% edge or vertex meanwhile the initial direction is outward
	global state_;
	global state_;
	global state_;
	global state_;
	
	e0out = e0in;
	paraCoord0out = paraCoord0in;
	localFrame0out = localFrame0in; 
	t1out = t1in;
	t2out = t2in;
	v0out = v0in;
	iEleType = state_.meshTypeMap_(e0in);
	tolEff = 1.0e6 * eps(1.0);
	s = paraCoord0in(1); t = paraCoord0in(2);
	if strcmp(iEleType, 'T3') || strcmp(iEleType, 'T6')
		%%Edge-Vertex Check
		if s<tolEff || t<tolEff || s+t > 1-tolEff
			if norm([s t]) < tolEff || norm([s t]) > 1 - tolEff %% at Vertex
				% warning('Approaching Vertex!');
				[~, nodeID] = min(vecnorm([s t] - [0 0; 1 0; 0 1], 2, 2));
				[e0out, paraCoord0out, localFrame0out, t1out, t2out, v0out] = ...
					psl.mesh.TransferToNextElement_StandardSharedNodeCase(nodeID, e0in, [s t], localFrame0in, t1in, t2in, v0in);
			else %% at Edge
				% warning('Approaching Edge!');
				if s < tolEff
					s = round(s);
					edgeID = 3;
				end
				if t < tolEff
					t = round(t);
					edgeID = 1;
				end
				if 1-s-t < tolEff
					edgeID = 2;
				end
				eNormal = psl.mesh.DetermineExternalNormalOfGivenEdgeInLocalFrame(e0in, edgeID);
				if acos(eNormal*v0in') > pi/2 %%v0in is inward
					return
				else
					e1 = state_.eleStruct_(e0in).edge2nextEle(edgeID);
					if 0==e1, return; end %%approaching boundary
					[e0out, paraCoord0out, localFrame0out, t1out, t2out, v0out] = ...
						psl.mesh.TransferToNextElement_StandardSharedEdgeCase(e0in, edgeID, [s t], iEleType, e1, v0in, localFrame0in);						
				end
			end
		else
			return
		end
	elseif strcmp(iEleType, 'Q4') || strcmp(iEleType, 'Q8')
		%%Edge-Vertex Check
		if s < -1+tolEff || s > 1-tolEff || t < -1+tolEff || t > 1-tolEff
			if norm([s t]) > sqrt(2) - tolEff %% at Vertex
				% warning('Approaching Vertex!');
				[~, nodeID] = min(vecnorm([s t] - [-1 -1; 1 -1; 1 1; -1 1], 2, 2));
				[e0out, paraCoord0out, localFrame0out, t1out, t2out, v0out] = ...
					psl.mesh.TransferToNextElement_StandardSharedNodeCase(nodeID, e0in, [s t], localFrame0in, t1in, t2in, v0in);				
			else %% at Edge
				% warning('Approaching Edge!');
				if s < -1+tolEff
					s = round(s);
					edgeID = 4;
				elseif s > 1-tolEff
					s = round(s);
					edgeID = 2;
				end
				if t < -1+tolEff
					t = round(t);
					edgeID = 1;
				elseif t > 1-tolEff
					t = round(t);
					edgeID = 3;
				end
				eNormal = psl.mesh.DetermineExternalNormalOfGivenEdgeInLocalFrame(e0in, edgeID);
				if acos(eNormal*v0in') > pi/2 %%v0in is inward
					return
				else
					e1 = state_.eleStruct_(e0in).edge2nextEle(edgeID);
					if 0==e1, return; end %%approaching boundary
					[e0out, paraCoord0out, localFrame0out, t1out, t2out, v0out] = ...
						psl.mesh.TransferToNextElement_StandardSharedEdgeCase(e0in, edgeID, [s t], iEleType, e1, v0in, localFrame0in);			
				end
			end		
		else
			return
		end
	else
		error('Un-supported Element type!');
	end
end

