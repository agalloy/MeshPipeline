%% This is a program for classifying the cavity filling into lobes.
% Created on 07/12/2021 by Hannah Borges

%% Initialize MATLAB
clear
clc
addpath(GIBBONPATH())

%% Initial parameters
leftLungNames = ["LUL", "LLL"];
rightLungNames = ["RUL", "RML", "RLL"];
leftLungID = [1, 2, 6];
rightLungID = [3, 4, 5, 7];
patientID = input('Input patient identification number: ', 's');

%% Step 1: Loading a lung segmentation 

% Selecting a file
default_dir = 'My/Directory/With/Images';
[image_name, image_dir] = uigetfile('.hdr', 'Select an Image File', default_dir);
image_path = fullfile(image_dir, image_name);

% Get image extension
[~,~,image_ext] = fileparts(image_path);

% Use the appropriate commands to open the file depending on the extension
if strcmp('.hdr',image_ext)
    % Get the meta data for the analyze 75 formatted image
    image_info = analyze75info(image_path);

    % Read the analyze 75 formatted image
    image = analyze75read(image_info);
    
elseif strcmp('.nii',image_ext)
    % Read nifti file
    image = niftiread(image_path);
    
    % Get nifti meta-data
    image_info = niftiinfo(image_path);
        
end

% Get voxel size
voxel_size = image_info.PixelDimensions(1:3);

%% Step 2: Classifying cavity filling

% Left lung 

lung_image = ismember(image, leftLungID);

LUL_mask = image == leftLungID(1); 
LLL_mask = image == leftLungID(2); 
FL_mask = image == leftLungID(3); 

LUL_dist = bwdist(LUL_mask);
LLL_dist = bwdist(LLL_mask);

FL_voxels = find(FL_mask);

for i = 1:length(FL_voxels)
    upperDist = LUL_dist(FL_voxels(i));
    lowerDist = LLL_dist(FL_voxels(i));
    if upperDist < lowerDist
        image(FL_voxels(i)) = leftLungID(1); 
    else 
        image(FL_voxels(i)) = leftLungID(2); 
    end 
end 

% Right lung 

lung_image = ismember(image, rightLungID);

RUL_mask = image == rightLungID(1); 
RML_mask = image == rightLungID(2); 
RLL_mask = image == rightLungID(3);
FR_mask = image == rightLungID(4); 

RUL_dist = bwdist(RUL_mask);
RML_dist = bwdist(RML_mask);
RLL_dist = bwdist(RLL_mask);

FR_voxels = find(FR_mask);

for i = 1:length(FR_voxels)
    upperDist = RUL_dist(FR_voxels(i));
    middleDist = RML_dist(FR_voxels(i));
    lowerDist = RLL_dist(FR_voxels(i));   
    
    if (upperDist < middleDist) && (upperDist < lowerDist)
        image(FR_voxels(i)) = rightLungID(1); 
    elseif (middleDist < lowerDist) 
        image(FR_voxels(i)) = rightLungID(2); 
    else 
        image(FR_voxels(i)) = rightLungID(3);
    end 
end 

%Get image size
image_size = size(image);

%Extract an image slice
%Note that by convention the "X" coordinate typically referes to the 2nd image index
%and the "Y" coordinate typically refers to the 1st
sliceXZ = image(150,:,:);
sliceYZ = image(:,150,:);
sliceXY = image(:,:,150);

%The squeeze function removes array dimensions with a length of 1 to make
%our images truly 2D
sliceXZ = squeeze(sliceXZ);
sliceYZ = squeeze(sliceYZ);
sliceXY = squeeze(sliceXY);

%Start a new figure displaying the three slices
figure()
subplot(1,3,1)
imshow(sliceXZ',[])
xlabel('XZ (Coronal) Slice')
subplot(1,3,2)
imshow(sliceYZ',[])
xlabel('YZ (Saggital) Slice')
subplot(1,3,3)
imshow(sliceXY,[])
xlabel('XY (Axial) Slice')

%% Export to .nii file

filename = [patientID, '_baseTLC_lobemask_filled.nii'];
niftiwrite(image, filename, image_info);

