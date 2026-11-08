function [e0out, paraCoord0out, localFrame0out, t1out, t2out, v0out] = ...
			TransferToNextElement_StandardSharedEdgeCase(e0in, edgeID, e0Para, e0Type, e1, v0in, localFrame0in)
%% 【论文 §3.2, 图3】跨单元搬运：标准"共享边"情形——沿共享边把点从 e_n 搬到相邻单元 e_{n+1}。
	global state_;
	global state_;
	global state_;
	global state_;
	
	e1_edgeIDlocal = state_.eleStruct_(e0in).edgeIDsOfNextEle(edgeID);
	e1_sharedEdge_NatCoord = psl.mesh.ConvertNaturalCoordsAtSharedEdge(e0in, e0Para, edgeID, e0Type, ...
		state_.eleStruct_(e0in).vtxEdgesGlobal(edgeID,:), e1, e1_edgeIDlocal, state_.meshTypeMap_(e1), ...
			state_.eleStruct_(e1).vtxEdgesGlobal(e1_edgeIDlocal,:));
	v0inGlobal = psl.stress.GlobalFrame2Local_Vecs(v0in, localFrame0in, 0);
	switch state_.meshTypeMap_(e1)
		case 'T3'
			iEleCoords = state_.nodeCoords_(state_.eNodMat_(e1,1:3),:);
		case 'T6'
			iEleCoords = state_.nodeCoords_(state_.eNodMat_(e1,1:6),:);
		case 'Q4'
			iEleCoords = state_.nodeCoords_(state_.eNodMat_(e1,1:4),:);
		case 'Q8'
			iEleCoords = state_.nodeCoords_(state_.eNodMat_(e1,1:8),:);	
	end
	[e1R, ~, e1t1, e2t2] = psl.mesh.ComputeLocalFrameAtGivenPosition(e1_sharedEdge_NatCoord, iEleCoords, state_.meshTypeMap_(e1));
	v0outLocal = psl.stress.GlobalFrame2Local_Vecs(v0inGlobal, e1R, 1);
	
	
	e0out = e1;
	paraCoord0out = e1_sharedEdge_NatCoord;
	localFrame0out = e1R; 
	t1out = e1t1;
	t2out = e2t2;
	v0out = v0outLocal;		
end

