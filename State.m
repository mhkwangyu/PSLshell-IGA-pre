classdef State < handle
    %STATE  Shared computation state (replaces the 48 global variables in
    %the legacy PSLshell.m).  Handle semantics: functions receive the same
    %object reference, so any `state.field = ...` mutation is shared, closely
    %mirroring the original `global` behaviour while making dependencies
    %explicit and testable.
    %
    %Fields are grouped to mirror the original GlobalVariables() layout.

    properties
        % --- Mesh / domain ---
        boundingBox_ = [];
        meshType_ = [];
        frameType_ = [];
        meshOrder_ = [];
        numNodes_ = 0;
        nodeCoords_ = [];
        numEles_ = 0;
        eNodMat_ = [];
        eleCentroids_ = [];
        meshTypeMap_ = [];

        % --- Stress fields ---
        localStressField_ = [];
        globalStressField_ = [];
        localStressFieldPerEle_ = [];
        globalStressFieldPerEle_ = [];
        nodeWiseStressField_ = [];

        % --- Boundary conditions ---
        loadingCond_ = [];
        fixingCond_ = [];

        % --- Derived mesh structures ---
        silhouetteStruct_ = [];
        eleCharacterSizeList_ = [];
        shellEleNormals_ = [];
        shellCurvatureScaling_ = [];
        nodStruct_ = [];
        eleStruct_ = [];
        boundaryElements_ = [];
        voidEleMap_ = [];
        triangularizedMesh_ = [];
        triangularizedMeshGraph_ = [];

        % --- Macros / frames ---
        refVec_ = [1 0 0];
        refVecFallback_ = [0 0 1];
        tolRefVecFallback_ = 1.0e-6;

        % --- Algorithm control ---
        tracingSche_ = 'RK2';
        approxiInterp_ = 0;
        scalingStepSize4PSL_ = 5;
        limitSteps_ = 2000;
        permittedMaxAdjacentTangentAngleDeviation_ = 45;
        refScalingSize_ = [];

        % --- Seeding ---
        seedPointsRef_ = [];
        seedPoints_ = [];
        seedPointsValence_ = [];
        iniSeedPoints_ = [];
        distanceMetric_ = '';
        mergingThreshold_ = [];

        % --- Results ---
        majorPSLpool_ = [];
        minorPSLpool_ = [];
        majorCoordList_ = [];
        minorCoordList_ = [];
        candidateElementsIncDegePts_ = [];
        degePts_ = [];
    end

    methods
        function obj = State()
            % Normalize the two reference vectors (mirror GlobalVariables()).
            obj.refVec_ = obj.refVec_ / norm(obj.refVec_);
            obj.refVecFallback_ = obj.refVecFallback_ / norm(obj.refVecFallback_);
        end
    end
end