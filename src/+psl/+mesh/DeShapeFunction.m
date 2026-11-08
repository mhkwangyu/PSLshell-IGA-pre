function [dNds, dNdt] = DeShapeFunction(paras, elementType)
%% 【论文 §2.1】形函数对自然坐标的一阶导数 dN/dξ、dN/dη。
%% 用于求切向量 t1,t2（抛物线/双二次单元的切平面随 (ξ,η) 变化）。
	numSamps = size(paras,1);
	s = paras(:,1);
	t = paras(:,2);	
	
	switch elementType
		case 'T3'
			dNds = zeros(numSamps,3); 
			dNdt = zeros(numSamps,3);
			
			dNds(:,1) = -ones(numSamps,1); 
			dNdt(:,1) = -ones(numSamps,1);
			dNds(:,2) = ones(numSamps,1);
			dNdt(:,2) = zeros(numSamps,1);
			dNds(:,3) = zeros(numSamps,1);
			dNdt(:,3) = ones(numSamps,1);			
		case 'T6'
			dNds = zeros(numSamps,6);
			dNdt = zeros(numSamps,6);
			
			dNds(:,1) = 4*s + 4*t - 3;
			dNdt(:,1) = 4*s + 4*t - 3;
			dNds(:,2) = 4*s - 1;
			dNdt(:,2) = zeros(numSamps,1);					
			dNds(:,3) = zeros(numSamps,1);
			dNdt(:,3) = 4*t - 1;						
			dNds(:,4) = 4 - 4*t - 8*s;
			dNdt(:,4) = -4*s;						
			dNds(:,5) = 4*t;
			dNdt(:,5) = 4*s;	
			dNds(:,6) = -4*t;
			dNdt(:,6) = 4 - 8*t - 4*s;			
		case 'Q4'
			dNds = zeros(numSamps,4);
			dNdt = zeros(numSamps,4);	

			dNds(:,1) = -0.25*(1-t);
			dNdt(:,1) = -0.25*(1-s);
			dNds(:,2) = 0.25*(1-t);
			dNdt(:,2) = -0.25*(1+s);					
			dNds(:,3) = 0.25*(1+t);
			dNdt(:,3) = 0.25*(1+s);						
			dNds(:,4) = -0.25*(1+t);
			dNdt(:,4) = 0.25*(1-s);			
		case 'Q8'
			dNds = zeros(numSamps,8);
			dNdt = zeros(numSamps,8);					

			dNds(:,1) = -(s/4 - 1/4).*(t - 1) - ((t - 1).*(s + t + 1))/4;
			dNdt(:,1) = -(s/4 - 1/4).*(t - 1) - (s/4 - 1/4).*(s + t + 1);	
			dNds(:,2) = ((t - 1).*(t - s + 1))/4 - (s/4 + 1/4).*(t - 1);
			dNdt(:,2) = (s/4 + 1/4).*(t - s + 1) + (s/4 + 1/4).*(t - 1);	
			dNds(:,3) = (s/4 + 1/4).*(t + 1) + ((t + 1).*(s + t - 1))/4;
			dNdt(:,3) = (s/4 + 1/4).*(t + 1) + (s/4 + 1/4).*(s + t - 1);	
			dNds(:,4) = (s/4 - 1/4).*(t + 1) + ((t + 1).*(s - t + 1))/4;
			dNdt(:,4) = (s/4 - 1/4).*(s - t + 1) - (s/4 - 1/4).*(t + 1);	
			dNds(:,5) = s.*(t - 1);
			dNdt(:,5) = s.^2 /2 - 1/2;	
			dNds(:,6) = 1/2 - t.^2 /2;
			dNdt(:,6) = -2*t.*(s/2 + 1/2);	
			dNds(:,7) = -s.*(t + 1);
			dNdt(:,7) = 1/2 - s.^2 /2;	
			dNds(:,8) = t.^2 /2 - 1/2;
			dNdt(:,8) = 2*t.*(s/2 - 1/2);		
		otherwise
			error('Un-supported Element Type!');
	end
end

