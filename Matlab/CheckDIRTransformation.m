% A script for checking how much the transformed TLC mask lines up with the
% FRC mask

%% Initialize Matlab
clear
clc
tic
%% User Parameters
% TLC Mask
mask_dir = 'X:\FissureIntegrity\IntegrityNet_Data\';
TLC_name = 'UT172269\seg\UT172269_V1_INSP_resampled.lobe.nii.gz';
% FRC Mask
FRC_name = 'UT172269\seg\UT172269_V1_EXP_resampled.lobe.nii.gz';
% DVF Data
dvf_dir = 'W:\BioMechStudy_Visit1_AllSub\normal';
dvf_file = '..\DispFields\UT172269\SSTVD_Both\deformationField.nii.gz';

%% Open mask and dvf files and metadata
% TLC
TLC_file = fullfile(mask_dir,TLC_name);
TLC_info = niftiinfo(TLC_file);
TLC_mask = niftiread(TLC_info);
T_TLC = TLC_info.Transform.T;
TLC_size = size(TLC_mask);

% FRC
FRC_file = fullfile(mask_dir,FRC_name);
FRC_info = niftiinfo(FRC_file);
FRC_mask = niftiread(FRC_info);
T_FRC = FRC_info.Transform.T;
FRC_size = size(FRC_mask);

% DVF
dvf_info = niftiinfo(dvf_file);
dvf = niftiread(dvf_info);
T_dvf = dvf_info.Transform.T;
dvf_size = size(dvf);

%% Get deformed mask on TLC grid using DVF
def_mask = zeros(size(TLC_mask));
% Get all deformed mask indices in one big array
[I_TLC, J_TLC, K_TLC] = meshgrid( 1:size(def_mask,1), 1:size(def_mask,2), 1:size(def_mask,3) );
ind_def = [ reshape(I_TLC,[],1), reshape(J_TLC,[],1), reshape(K_TLC,[],1) ];
ind_def1 = [ind_def, ones(size(ind_def,1),1)];
% Convert those indices into dvf indices
ind_dvf1 = ind_def1 * T_TLC * T_dvf^(-1);
% Interpolate displacement values at the dvf indices
u_dvf1 = ones(size(ind_def1));
for i = 1:3
    u_grid = squeeze( dvf(:,:,:,1,i) );
    u_dvf1(:,i) = interp3( u_grid, ind_dvf1(:,2), ind_dvf1(:,1), ind_dvf1(:,3) );
end
% Convert displaced indices in dvf space to FRC indices
%ind_FRC1 = (ind_dvf1 + u_dvf1) * T_dvf * T_FRC^(-1);
ind_FRC1 = ind_def1 + u_dvf1;
% Interpolate mask values at those indices
mask_values = interp3( double(FRC_mask), ind_FRC1(:,2), ind_FRC1(:,1), ind_FRC1(:,3) );
mask_values( isnan(mask_values) ) = 0;
% Convert deformed image indices to linear indices
ind_linear = sub2ind( size(def_mask), ind_def(:,1), ind_def(:,2), ind_def(:,3) );
% Set mask values at those linear indices
def_mask(ind_linear) = mask_values;

%% Slice viewer
% figure()
% sliceViewer(TLC_mask)
% title('TLC Mask')
% 
% figure()
% sliceViewer(FRC_mask)
% title('FRC Mask')
% 
% figure()
% sliceViewer(def_mask)
% title('Deformed Mask')

% Quantify alignment
vol_TLC = sum(TLC_mask > 0.5, 'all');
vol_def = sum(def_mask > 0.5, 'all');
overlap = (TLC_mask>0.5) & (def_mask>0.5);
overlap = sum(overlap,'all');
dice_coeff = 2*overlap / (vol_TLC + vol_def);
fprintf( '\nDice coefficient between registrered TLC mask and FRC mask: %d\n', dice_coeff )
fprintf( 'Ratio of registered mask volume to FRC volume: %d\n', vol_def/vol_TLC )

%% Create surfaces for comparison
origin = T_FRC(4,1:3);
controlPar.contourLevel = 0;
controlPar.voxelSize = [1 1 1];
controlPar.nSub = [4 4 4];
controlPar.capOpt = 1;

% TLC surface
levelset_TLC = logic2levelset(TLC_mask > 0.5);
[F_TLC, V_TLC] = levelset2isosurface(levelset_TLC, controlPar);
V_TLC = V_TLC + origin([2,1,3]) .* [-1,-1,1];
% FRC surface
levelset_FRC = logic2levelset(FRC_mask > 0.5);
[F_FRC, V_FRC] = levelset2isosurface(levelset_FRC, controlPar);
V_FRC = V_FRC + origin([2,1,3]) .* [-1,-1,1];
% Deformed surface
levelset_def = logic2levelset(def_mask > 0.5);
[F_def, V_def] = levelset2isosurface(levelset_def, controlPar);
V_def = V_def + origin([2,1,3]) .* [-1,-1,1];

%% Interpolate displacments onto TLC surface to compare displaced and FRC
% Interpolate displacements
% u = SampleDispField(V_TLC,dvf_file);
% V_def = V_TLC + u;
% F_def = F_TLC;

%% Plot surfaces
figure(); 
hold on; 
title('FRC surface')
gpatch(F_FRC, V_FRC,'gw'); 
camlight headlight;
drawnow; 
daspect([1,1,1]);
hold off

figure(); 
hold on; 
title('TLC Vs. Deformed surface')
gpatch(F_TLC, V_TLC,'gw'); 
gpatch(F_def, V_def,'rw'); 
camlight headlight;
drawnow; 
daspect([1,1,1]);
hold off

figure(); 
hold on; 
title('FRC vs. Deformed surface')
gpatch(F_def, V_def,'gw');
gpatch(F_FRC, V_FRC,'rw');
camlight headlight;
drawnow; 
daspect([1,1,1]);
hold off

toc