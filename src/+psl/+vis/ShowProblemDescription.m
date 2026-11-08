function ShowProblemDescription()
	global state_;
	global state_;
	global state_;
	global state_;
	global state_;

	
	hd = patch(state_.silhouetteStruct_); hold('on');
	set(hd, 'FaceColor', [65 174 118]/255, 'FaceAlpha', 1.0, 'EdgeColor', 'k');
    if ~isempty(state_.loadingCond_)
		lB = 0.2; uB = 1.0;
		amps = vecnorm(state_.loadingCond_(:,2:4),2,2);
		maxAmp = max(amps); minAmp = min(amps);
		if abs(minAmp-maxAmp)/(minAmp+maxAmp)<0.1
			scalingFac = 1;
		else
			if minAmp/maxAmp>lB/uB, lB = minAmp/maxAmp; end
			scalingFac = lB + (uB-lB)*(amps-minAmp)/(maxAmp-minAmp);
		end
		loadingDirVec = state_.loadingCond_(:,2:4)./amps.*scalingFac;
		coordLoadedNodes = state_.nodeCoords_(state_.loadingCond_(:,1),:);
		amplitudesF = mean(state_.boundingBox_(2,:)-state_.boundingBox_(1,:))/5 * loadingDirVec;
		hold('on'); quiver3(coordLoadedNodes(:,1), coordLoadedNodes(:,2), coordLoadedNodes(:,3), amplitudesF(:,1), ...
			amplitudesF(:,2), amplitudesF(:,3), 0, 'Color', [255 127 0.0]/255, 'LineWidth', 2, 'MaxHeadSize', 1, 'MaxHeadSize', 1);
	end
    if ~isempty(state_.fixingCond_)
		tarNodeCoord = state_.nodeCoords_(state_.fixingCond_(:,1),:);
		hold('on'); hd1 = plot3(tarNodeCoord(:,1), tarNodeCoord(:,2), tarNodeCoord(:,3), 'x', ...
			'color', [153 153 153]/255, 'LineWidth', 3, 'MarkerSize', 15);		
    end
	if ~isempty(find(0==(state_.boundingBox_(2,:)-state_.boundingBox_(1,:)))) %%2D
		view(2);
	else
		view(3);
	end
	axis(gca, 'equal'); 
	axis(gca, 'tight');
	axis(gca, 'off');
end

