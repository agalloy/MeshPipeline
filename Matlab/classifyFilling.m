%% This is a program for classifying the cavity filling into lobes.
% Created on 07/12/2021 by Hannah Borges

%% Initialize MATLAB
clear
clc

%% Initial parameters
lobeID = [1,2,3,4,5];
fillID = 6;
patientID = input('Input patient identification number: ', 's');

%% Step 1: Loading a lung segmentation 

% Selecting a file
default_dir = pwd();
[mask_name, mask_dir] = uigetfile('', 'Select an Image File', default_dir);
mask_path = fullfile(mask_dir, mask_name);

% Get image extension
[~,~,mask_ext] = fileparts(mask_path);

% Use the appropriate commands to open the file depending on the extension
if strcmp('.hdr',mask_ext)
    % Get the meta data for the analyze 75 formatted image
    mask_info = analyze75info(mask_path);

    % Read the analyze 75 formatted image
    mask = analyze75read(mask_info);
    
elseif strcmp('.nii',mask_ext)
    % Read nifti file
    mask = niftiread(mask_path);
    
    % Get nifti meta-data
    mask_info = niftiinfo(mask_path);
    
else
    % Read nifti file
    mask = niftiread(mask_path);
    
    % Get nifti meta-data
    mask_info = niftiinfo(mask_path);
        
end

% Get voxel size
voxel_size = mask_info.PixelDimensions(1:3);

%% Step 2: Classifying cavity filling
% Get the filling voxels
fill_voxels = find ( ismember(mask,fillID) );

% Loop through every lobe and find distance from filling to that lobe
% Initialize arrays
fill_dist = ones(size(fill_voxels)) * 10^6;
fill_lobe = nan(size(fill_voxels));
for i = 1:size(lobeID,2)
    % Get the mask of the current lobe
    lobe_mask = mask == lobeID(i);
    % Compute the distance function wrt the current lobe
    lobe_dist = bwdist(lobe_mask);
    % Evaluate the distance at each filled voxel from the current lobe
    fill_dist_new = lobe_dist(fill_voxels);
    
    % Find the voxels closer to the current lobe than any previous one
    closer = fill_dist > fill_dist_new;
    % Update the closest lobe and distance for those voxels 
    fill_dist(closer) = fill_dist_new(closer);
    fill_lobe(closer) = lobeID(i);
end

% Classify the filled voxel regions according to their closest lobe
mask(fill_voxels) = fill_lobe;

%% View filled segmentation slices
figure()
orthosliceViewer(mask)


%% Export to .nii file

out_name = [patientID, '_baseTLC_lobemask_filled.nii'];
out_dir = mask_dir;
out_path = fullfile(out_dir, out_name);
niftiwrite(mask, out_path, mask_info);

