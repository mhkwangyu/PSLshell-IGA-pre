%%PSLshell
%%Date: 	2025.09.30
%%Author:	Junpeng Wang (junpeng.wang@tum.de; junwa@dtu.dk)

%%This repository is the associated software of the paper: 
%% "Topology-aware Stress Analysis in Shell Structures"
%% by Junpeng Wang, Yingjian Liu, Jun Wu, and Rüdiger Westermann.
%% Preprint can be found at https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5776659


function PSLshell(fileName, profile, opts)
%% Minimal entry refactor (script -> function). No algorithm change.
%% Usage:
%%   PSLshell                                -> default cylinder_1_Q4 with paper profile
%%   PSLshell(stressfileName)                -> custom data file (without .TSV)
%%   PSLshell(stressfileName, profile)       -> custom tracing profile
%%   PSLshell(stressfileName, profile, opts) -> opts.showProblem / opts.showPSLs / opts.saveFig
if nargin < 1 || isempty(fileName), fileName = './data/cylinder_1_Q4'; end
if nargin < 2 || isempty(profile), profile = pslDefaultProfile(); end
if nargin < 3 || isempty(opts), opts = struct(); end
if ~isfield(opts,'showProblem'), opts.showProblem = 1; end
if ~isfield(opts,'showPSLs'),    opts.showPSLs    = 1; end
if ~isfield(opts,'saveFig'),     opts.saveFig     = ''; end

clear global;
initState();

%%1. Import Data
tStart = tic;
psl.io.ImportStressFields(strcat(fileName, '.TSV'));
disp(['Import Stress Field Costs: ' sprintf('%10.3g',toc(tStart)) 's']);

%%2. Pre-process Data
tStart = tic;
psl.mesh.PreProcessData();
disp(['Pre-process Data Costs: ' sprintf('%10.3g',toc(tStart)) 's']);
if opts.showProblem, figure; psl.vis.ShowProblemDescription(); end

if 1 %% PSLs Generation
	%%3. Seeding PSLs
	tStart = tic;
	psl.trace.SeedingPSLs(profile); 
	disp(['Seeding PSL Costs: ' sprintf('%10.3g',toc(tStart)) 's']);
	
	%%3. Vis.
	if opts.showPSLs, psl.vis.ShowPSLs('None', 'None', 1.0, 20); end
	if ~isempty(opts.saveFig)
		print('-dpng', '-r300', opts.saveFig);
		close(gcf);
	end
	% ShowPrincipalStressDirectionsByArrowsGlobally(); %%Show Principal Stress Directions via Arrows
else %% Check Mesh Normals
	%%3. Evaluate Element Normals
	faceNormals = psl.mesh.EvaluateMeshNormals();
	figure; psl.vis.ShowMeshNormals(faceNormals);
	% optFlipNormal = 1;
	% if optFlipNormal %% If the normals are not outward
		% stressfileNameNew = strcat(stressfileName, '_new');
		% ExportStressFieldWithFlippedNormals(strcat(stressfileNameNew, '.TSV'));
	% end	
end
end %% PSLshell (main function end)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Source
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function initState()
%% Construct the computation-state handle (replaces the former GlobalVariables).
%% Defensive: if a previous handle is still referenced, destroy it first to
%% avoid accumulating State handles across repeated calls in one session.
global state_;
	if ~isempty(state_), delete(state_); end
	state_ = State();
end


function profile = pslDefaultProfile()
%% Default tracing profile (paper: #Cylinder / #Dome)
	profile = struct(...
		'PSLsDensityCtrl',		10,				...	%% minDim/PSLsDensityCtrl ('\omega in the paper')
		'PSLtypeCtrl',			[0 0], 			... %% [major, minor], 0==generate, 1==skip
		'topologyAware',		1, 				... %% Enable Topology Analysis
		'distanceMetric',		'Euclidean', 	... %% 'Euclidean', 'Geodesic'
		'seedSparsityCtrl',		1,				... %% Every 'value' element is sampled
		'maxIts',				1000			... %% Maximum Integration Steps in a Single Run of PSL Tracing
	);
end


