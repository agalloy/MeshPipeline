%% This is a function for creating lung FE meshes from segmentation data.
% Created on 06/21/2021 by Hannah Borges
% Updated on 10/12/2022 by Ryan Langstraat and Adam Galloy
% Inputs: voxel_size, image, options
%   voxel_size = dimensions of the image voxels in the file 
%       image is a binary mask
%   output_name = desired output name for the file generated 
%   options = a structure containing additional options

function [NodeArray, ElementArray] = MeshMaskRegion(voxel_size, image, options)
%% Parse options structure
if isfield(options,'tetFill')
    tetFill = options.tetFill;
else
    tetFill = 0;
end
if isfield(options,'stl_file')
    save_stl = 1;
    stl_file = options.stl_file;
else
    save_stl = 0;
end
if isfield(options,'plots')
    if strcmp(char(options.plots),'all')
        plots = ["LevelSet","InitialSurface","RemeshedSurface",...
                 "SmoothedSurface", "FilledMesh"];
    else
        plots = options.plots;
    end
else
    plots = "none";
end
if isfield(options,'anisotropy')
    anisotropy = options.anisotropy;
else
    anisotropy = 0;
end
%% Step 1: Getting the levelsets from the segmentation

% Convert segmentation into levelsets
levelset = logic2levelset(image,voxel_size);

% View zero points of levelset
if ismember("LevelSet", plots)
    zero_contour = levelset == 0;
    
    figure()
    orthosliceViewer(zero_contour)
    title('Zero Contour')
end

%% Step 2: Getting surfaces from the levelset

% Set parameters
controlPar.contourLevel = 0;
controlPar.voxelSize = voxel_size;
controlPar.nSub = [1 1 1];
controlPar.capOpt = 1;

[ElementArray, NodeArray] = levelset2isosurface(levelset, controlPar);

% Check for holes in mesh using Euler Characteristic
chi = eulerChar(ElementArray, NodeArray);
if chi ~= 2
    warning('Warning voxelated surface may have holes.')
end

% View initial surface
if ismember("InitialSurface",plots)
    figure(); 
    hold on; 
    title('Initial surface')
    gpatch(ElementArray, NodeArray,'gw'); 
    camlight headlight;
    drawnow; 
    daspect([1,1,1]);
    set(gca, 'Zdir', 'reverse')
    hold off
end
 
%% Step 3: Reduce the number of triangles on the surface
% Calculating number of nodes required for given point spacing
pointSpacing = 6; % Desired point spacing 

A = patchArea(ElementArray, NodeArray); % Areas of current faces
totalArea = sum( A ); % Total area
l = sqrt(totalArea); % Width or length of square with same size
numPoints = round((l./pointSpacing).^2); % Point spacing for mesh in virtual square

% Remesh options
optionStruct.nb_pts = numPoints;
optionStruct.anisotropy = anisotropy;
[ElementArray, NodeArray] = ggremesh(ElementArray, NodeArray, optionStruct);

% Check for holes in mesh using Euler Characteristic
chi2 = eulerChar(ElementArray, NodeArray);
if chi2 ~= 2
    warning('Warning remeshed surface may have holes.')
end

% Evaluate Surface Metrics
% Calculate Regularity of Mesh
TR = triangulation(ElementArray, NodeArray);
V = vertexAttachments(TR);
numAdj = cellfun(@numel, V);

[count,~] = hist(numAdj,1:10);
disp('Histogram of number of faces neighboring each node:')
disp(100*count / sum(count))

% Calculate the max angles
maxTheta = maxTriSurfAngle(NodeArray, ElementArray);
disp('Mean Max Dihedral Angle: Remeshed Surface')
disp(mean(maxTheta))

% View remeshed surface 
if ismember("RemeshedSurface", plots)
    figure();
    hold on 
    title('Remeshed Surface')
    gpatch(ElementArray, NodeArray,'gw'); 
    camlight headlight;
    drawnow; 
    daspect([1,1,1]);
    set(gca, 'Zdir', 'reverse')
    hold off
end

%% Step 4: Smooth the new mesh

% Smoothing parameters
cParSmooth.Method = 'HC'; % Humphrey's Classes smoothing
cParSmooth.Alpha = 0.1;
cParSmooth.Beta = 0.5;
cParSmooth.n = 50; % Number of iterations

% Smooth the mesh
[NodeArray] = patchSmooth(ElementArray, NodeArray, [], cParSmooth);

% Evaluate Surface Metrics
% Calculate Regularity of Mesh
TR = triangulation(ElementArray, NodeArray);
V = vertexAttachments(TR);
numAdj = cellfun(@numel, V);

% Calculate the max angles
maxTheta = maxTriSurfAngle(NodeArray, ElementArray);
disp('Mean Dihedral Angle: Smoothed Surface:')
disp(mean(maxTheta))

% View smoothed surface 
if ismember("SmoothedSurface",plots)
    figure();
    hold on 
    title('Smoothed Surface')
    gpatch(ElementArray, NodeArray,'gw'); 
    camlight headlight;
    daspect([1 1 1]);
    set(gca, 'Zdir', 'reverse')
    drawnow; 
    hold off
end

%% Optional Step: Export the smoothed surface as stl
if save_stl
    disp('test1')

    % Create triangulation object
    tr = triangulation(ElementArray, NodeArray);
    disp('test2')

    % Export to .stl
    stlwrite(tr, stl_file);
    disp('test3')
end

%% Evaluate smoothed surface
% [smooth_error] = triSurfSetDist(ElementArray, NodeArray, ElementArray, NodeArray, 'dist-ray');

%% Running tetgen

if tetFill == 1
        
    NodeArray = double(NodeArray);
    C = ones(size(ElementArray,1),1); %Face boundary markers (aka face colors)
    V_regions = getInnerPoint(ElementArray, NodeArray); %Define region points
    V_holes = []; %Define hole points
    [regionTetVolumes] = tetVolMeanEst(ElementArray, NodeArray); %Volume estimate for regular tets
    stringOpt = '-pq1.2AaY'; %Options for tetgen
    
    % Creating tetgen input structure
    inputStruct.stringOpt = stringOpt; %Tetgen options
    inputStruct.Faces = ElementArray; %Boundary faces
    inputStruct.Nodes = NodeArray; %Nodes of boundary
    inputStruct.faceBoundaryMarker = C;
    inputStruct.regionPoints = V_regions; %Interior points for regions
    inputStruct.holePoints = V_holes; %Interior points for holes
    inputStruct.regionA = regionTetVolumes; %Desired tetrahedral volume for each region

    % Mesh model using tetrahedral elements using tetGen
    [meshOutput] = runTetGen(inputStruct); %Run tetGen
    
    ElementArray = meshOutput.elements; %The elements
    NodeArray = meshOutput.nodes; %The vertices or nodes
    CE = meshOutput.elementMaterialID; %Element material or region id
    Fb = meshOutput.facesBoundary; %The boundary faces
    Cb = meshOutput.boundaryMarker; %The boundary markers
    
    % Plotting structure 
    if ismember("FilledMesh",plots)
        fontSize = 15;
        faceAlpha1 = 0.3;
        faceAlpha2 = 1;
        cMap = gjet(4);
        patchColor = cMap(1,:);
        markerSize = 25;
        NodeArrayP = NodeArray.*[1,1,-1];
        
        hf=cFigure;
        subplot(1,2,1); hold on;
        title('Input boundaries','FontSize',fontSize);
        hp(1) = gpatch(Fb,NodeArrayP,Cb,'k',faceAlpha1);
        hp(2) = plotV(V_regions,'r.','MarkerSize',markerSize);
        legend(hp,{'Input mesh','Interior point(s)'},'Location','NorthWestOutside');
        axisGeom(gca,fontSize); camlight headlight;
        colormap(cMap); icolorbar;
        set(gca, 'Zdir', 'reverse')
        
        hs = subplot(1,2,2); hold on;
        title('Tetrahedral mesh','FontSize',fontSize);
        
        % Visualizing using |meshView|
        optionStruct.hFig = [hf,hs];
        meshView(meshOutput,optionStruct);
        axisGeom(gca,fontSize);
        set(gca, 'Zdir', 'reverse')
        gdrawnow;
    end 

end 