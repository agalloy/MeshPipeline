%% This is a program for automated creation of febio models from Lung CT scans
% Created on 10/12/2022 by Adam Galloy

% To Do:
%   - Retrieve mesh metrics from MeshPipeline to analyze all models together
%   - Make the user parameters for generating multiple models simpler
%   - Get the mesh output to work properly

%% Initialize MATLAB
clear
clc
if ~exist('logic2levelset')
    addpath(genpath('../../../GibbonCode'))
end

%% User parameters (Basic)
% Segmentation mask directory and pattern
mask_dir = '..\Segmentations';
mask_pattern = '${SUBJECT}\${SUBJECT}_baseTLC_lobemask_half.nii';

% Displacement field pattern
% Old data
%disp_pattern = '..\DispFields\${SUBJECT}\RegMask_Both\Disp12_${AXIS}_1_1_1_4_4_4.hdr';
% New data
disp_pattern = '..\DispFields\${SUBJECT}\Disp_Left.nii.gz';

% Output febio mesh model directory and pattern
feb_dir = '..\FEBio\Meshes\TetFactorStudy';
feb_pattern = '${SUBJECT}_${MODEL}_Mesh.feb';

% Path to .feb template
feb_template = 'FEBioMesh_Template.feb';

% List of subjects to process (as string array)
subjects = "MU160763";

%% User parameters (Advanced)
% String array of segmentation regions names
seg_regions = ["LTC","LUL","LLL","RTC","RUL","RML","RLL", "LeftLung", "RightLung"];
% Cell array containing mask ID's for each region (same order as names)
seg_maskIDs = {
               [1,2]
               1
               2
               [3,4,5]
               3
               4
               5
               [1,2]
               [3,4,5]
              };

% String array of model names
model_names = ["LeftLung_Lobes_tf1.1","LeftLung_Lobes_tf1.2","LeftLung_Lobes_tf1.5"];
          
% Cell array of segmentation regions to use for each model 
% e.g. For a left lung lobar model use ["LTC","LUL","LLL"], for a left lung
%   whole lung model use ["LTC"]
model_regions = {
                 ["LTC","LUL","LLL"]
                 ["LTC","LUL","LLL"]
                 ["LTC","LUL","LLL"]
                };
% Specify which model regions are volumetric and need tetradhedral filling
model_tetFill = {
                [0,1,1]
                [0,1,1]
                [0,1,1]
                };

% Specify anisotropy setting to use for each model
anisotropy = {0,0,0};
tetFactor = {1.1,1.2,1.5};

% Specify which plots you want (as a string array) from the following list:
% LevelSet, InitialSurface, RemeshedSurface, SmoothedSurface, FilledMesh
plot_list = "SmoothedSurface";
           
%% Loop through each subject and generate the desired models
num_subjects = length(subjects);
num_models = length(model_names);

tic
% Subject loop
for i = 1:length(subjects)
    subject = char(subjects(i));

% Open the segmentation mask
    % Get the mask filepath
    mask_name = replace(mask_pattern,'${SUBJECT}',subject);
    mask_file = fullfile(mask_dir,mask_name);
    % Get image extension
    [~,~,image_ext] = fileparts(mask_file);
    %Use the appropriate commands to open the file depending on the extension
    if strcmp('.hdr',image_ext)
        %Get the meta data for the analyze 75 formatted image
        mask_info = analyze75info(mask_file);
        %Read the analyze 75 formatted image
        mask = analyze75read(mask_info);
    elseif strcmp('.nii',image_ext)
        %Get nifti meta-data
        mask_info = niftiinfo(mask_file);
        %Read nifti file
        mask = niftiread(mask_file);
    else
        %Get nifti meta-data
        mask_info = niftiinfo(mask_file);
        %Read nifti file
        mask = niftiread(mask_file);
    end
    % Get voxel size
    voxel_size = mask_info.PixelDimensions(1:3);
    % Get image transformation matrix
    maskTransform = mask_info.Transform.T;
    
% Loop generating each model for the current subject
    for j = 1:num_models
        model = char(model_names(j));
        num_regions = length(model_regions{j});
        
    % Mesh each model region
        % Initialize arrays
        NodeCells = cell(num_regions,1);
        ElementCells = cell(num_regions,1);
        for k = 1:num_regions
            % Get the index of the current segmentation region
            region_name = model_regions{j}(k);
            regionID = find( strcmp(seg_regions,region_name) );
            if isempty(regionID)
                error('Unrecognized segmentation region used in model definition')
            end
            
            % Pre-process segmentation
            region_mask = ismember( mask, seg_maskIDs{regionID} );
            region_mask = cleanSegmentation( region_mask, 6 );
            % Assemble options structure
            options.tetFill = model_tetFill{j}(k);
            options.plots = plot_list;
            options.anisotropy = anisotropy{j};
            options.maskTransform = maskTransform;
            options.tetFactor = tetFactor{j};
            % Run mesh pipeline
            [NodeCells{k}, ElementCells{k}] = MeshMaskRegion( voxel_size, region_mask, options );
        end
      
        % Generate .feb file path
        feb_name = replace(feb_pattern,{'${SUBJECT}','${MODEL}'},{subject,model});
        feb_file = fullfile(feb_dir,feb_name);
        
        % Generate mesh2feb input structure
        site = subject(1:2);
        if strcmp(model_regions{j}(1),"LTC")
            side = 'left';
        elseif strcmp(model_regions{j}(1),"RTC")
            side = 'right';
        else
            side = '';
        end
        inStruct.NodeCells = NodeCells;
        inStruct.ElementCells = ElementCells;
        inStruct.model_regions = model_regions{j};
        inStruct.disp_pattern = replace(disp_pattern,{'${SUBJECT}','${SITE}','${SIDE}'},{subject,site,side});
        
        % Create mesh file
        mesh2feb(feb_file,feb_template,inStruct)
    end
end
toc