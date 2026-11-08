function ShowMeshNormals(faceNormals)
	global state_;
	hdEles = patch(state_.silhouetteStruct_); hold('on');
	hdNormals = quiver3(state_.eleCentroids_(:,1), state_.eleCentroids_(:,2), state_.eleCentroids_(:,3), faceNormals(:,1), faceNormals(:,2), faceNormals(:,3));
	set(hdEles, 'FaceColor', [65 174 118]/255, 'FaceAlpha', 1.0, 'EdgeColor', 'k');
	set(hdNormals, 'LineWidth', 0.5, 'Color', 'r', 'MaxHeadSize', 0.5);
	view(3);
	axis('equal', 'tight', 'off'); 	
end

