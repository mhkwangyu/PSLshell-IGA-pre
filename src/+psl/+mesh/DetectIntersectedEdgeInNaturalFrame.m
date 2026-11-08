function [edgeID, paraCoord1Fallback, successfulIntersection] = DetectIntersectedEdgeInNaturalFrame(p1, p2, eleType)
%% 【论文 §3.2, 图3】求线段 s_n→s_{n+1} 与当前等参单元顶点边的交点（跨单元四步的第1步）。
	edgeID = 0;
	paraCoord1Fallback = [];
	successfulIntersection = true;
	p1 = psl.mesh.AvoidExactLocationAtVertexOrEdge4Robustness(p1, eleType, 1.0e-4);
	tangent = p2 - p1;
	tolEff = 1.0e6 * eps(1.0); 
	if norm(tangent)<1.0e2*tolEff
		error('p2 coincides with p1!');
	end
	%%p1p2 -> y = a*x + b
	if abs(p2(1)-p1(1)) < tolEff 
		opt = 1; %%Parallel to y-axis
	elseif abs(p2(2)-p1(2)) < tolEff
		opt = 2; %% Parallel to x-axis
	else
		opt = 3; %% Arbitrary
		a = (p2(2)-p1(2))/(p2(1)-p1(1));
		b = p1(2) - a*p1(1);
	end
	lowerP12X = min([p1(1) p2(1)]); upperP12X = max([p1(1) p2(1)]);
	lowerP12Y = min([p1(2) p2(2)]); upperP12Y = max([p1(2) p2(2)]);
	
	if strcmp(eleType, 'T3') || strcmp(eleType, 'T6')
		switch opt
			case 1
				if p2(2)>1-p2(1)
					edgeID = 2;
					paraTmp = [p2(1) 1-p2(1)];
					if norm(paraTmp-p1)>tolEff
						paraCoord1Fallback = paraTmp;
					else
						edgeID = 0;
					end
				elseif p2(2) < 0
					edgeID = 1;
					paraTmp = [p2(1) 0];
					if norm(paraTmp-p1)>tolEff
						paraCoord1Fallback = paraTmp;
					else
						edgeID = 0;
					end					
				else
					disp(eleType);
					disp([p1; p2]);
					error('Unexpected Error in Detecting Intersected Edge In Natural Frame!');					
				end
			case 2
				if p2(1)>1-p2(2)
					edgeID = 2;
					paraTmp = [1-p2(2) p2(2)];
					if norm(paraTmp-p1)<tolEff
						error('p2 coincides with p1!');
					end
					paraCoord1Fallback = paraTmp;						
				elseif p2(1) < 0
					edgeID = 3;
					paraTmp = [0 p2(2)];
					if norm(paraTmp-p1)<tolEff
						error('p2 coincides with p1!');
					end
					paraCoord1Fallback = paraTmp;						
				else
					disp(eleType);
					disp([p1; p2]);
					error('Unexpected Error in Detecting Intersected Edge In Natural Frame!');							
				end
			case 3
				for ii=1:3
					switch ii
						case 1
							xi = (-b)/a;
							paraTmp = [xi 0];
							if xi<0 || xi>1, continue; end
							if xi<=lowerP12X || xi>=upperP12X, continue; end %% Out of segment p1p2
							if norm(paraTmp-p1)<tolEff, continue; end
							edgeID = ii;
							paraCoord1Fallback = paraTmp;									
							return	
						case 2
							if -1==a, continue; end %%Parallel to edge 2
							xi = (1-b)/(a+1);
							eta = 1-xi;
							paraTmp = [xi eta];
							if xi<0 || xi>1, continue; end
							if eta<0 || eta>1, continue; end
							if xi<=lowerP12X || xi>=upperP12X, continue; end %% Out of segment p1p2
							if norm(paraTmp-p1)<tolEff, continue; end
							edgeID = ii;
							paraCoord1Fallback = paraTmp;	                                
							return
						case 3
							eta = b;
							paraTmp = [0 eta];
							if eta<0 || eta>1, continue; end
							if eta<=lowerP12Y || eta>=upperP12Y, continue; end %% Out of segment p1p2
							if norm(paraTmp-p1)<tolEff, continue; end
							edgeID = ii;
							paraCoord1Fallback = paraTmp;										
							return										
					end
				end
		end	
	elseif strcmp(eleType, 'Q4') || strcmp(eleType, 'Q8')
		switch opt
			case 1
				if p2(2)>1
					edgeID = 3;
					paraTmp = [p2(1) 1];
					if norm(paraTmp-p1)>tolEff
						paraCoord1Fallback = paraTmp;
					else
						edgeID = 0; 
					end						
				elseif p2(2)<-1
					edgeID = 1;
					paraTmp = [p2(1) -1];
					if norm(paraTmp-p1)>tolEff
						paraCoord1Fallback = paraTmp;
					else
						edgeID = 0; 
					end							
				else
					disp(eleType);
					disp([p1; p2]);
					error('Unexpected Error in Detecting Intersected Edge In Natural Frame!');
				end		
			case 2
				if p2(1)>1
					edgeID = 2;
					paraTmp = [1 p2(2)];
					if norm(paraTmp-p1)>tolEff
						paraCoord1Fallback = paraTmp;
					else
						edgeID = 0; 
					end						
				elseif p2(1)<-1
					edgeID = 4;
					paraTmp = [-1 p2(2)];
					if norm(paraTmp-p1)>tolEff
						paraCoord1Fallback = paraTmp;
					else
						edgeID = 0; 
					end							
				else
					disp(eleType);
					disp([p1; p2]);
					error('Unexpected Error in Detecting Intersected Edge In Natural Frame!');
				end				
			case 3
				for ii=1:4
					switch ii
						case 1
							xi = (-1-b)/a;
							paraTmp = [xi -1];
							if xi<-1 || xi>1, continue; end
							if xi<=lowerP12X || xi>=upperP12X, continue; end %% Out of segment p1p2
							if norm(paraTmp-p1)<tolEff, continue; end
							edgeID = ii;
							paraCoord1Fallback = paraTmp;									
							return								
						case 2
							eta = a*1+b;
							paraTmp = [1 eta];
							if eta<-1 || eta>1, continue; end
							if eta<=lowerP12Y || eta>=upperP12Y, continue; end %% Out of segment p1p2
							if norm(paraTmp-p1)<tolEff, continue; end
							edgeID = ii;
							paraCoord1Fallback = paraTmp;									
							return	
						case 3
							xi = (1-b)/a;
							paraTmp = [xi 1];
							if xi<-1 || xi>1, continue; end
							if xi<=lowerP12X || xi>=upperP12X, continue; end %% Out of segment p1p2
							if norm(paraTmp-p1)<tolEff, continue; end
							edgeID = ii;
							paraCoord1Fallback = paraTmp;									
							return								
						case 4
							eta = -a*1+b;
							paraTmp = [-1 eta];
							if eta<-1 || eta>1, continue; end
							if eta<=lowerP12Y || eta>=upperP12Y, continue; end %% Out of segment p1p2
							if norm(paraTmp-p1)<tolEff, continue; end
							edgeID = ii;
							paraCoord1Fallback = paraTmp;									
							return		
					end
				end
		end	
	else
		error('Un-supported Element type!');
	end
	
	if 0==edgeID
		successfulIntersection = false;
	end
end

