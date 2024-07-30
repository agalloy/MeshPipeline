% Try interpolating from the TLC to FRC dvf instead of the FRC to TLC dvf.
% This first requires inverting the transformation.

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
dvf_file = '..\DispFields\UT172269\SSTVD_Both\deformationField_TLCtoFRC.nii.gz';

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

%% Get deformed mask on FRC grid using DVF
def_mask = zeros(size(FRC_mask));
% Get all deformed mask indices in one big array
[I_FRC, J_FRC, K_FRC] = meshgrid( 1:size(def_mask,1), 1:size(def_mask,2), 1:size(def_mask,3) );
ind_def = [ reshape(I_FRC,[],1), reshape(J_FRC,[],1), reshape(K_FRC,[],1) ];
ind_def1 = [ind_def, ones(size(ind_def,1),1)];
% Convert those indices into dvf indices
ind_dvf1 = ind_def1 * T_FRC * T_dvf^(-1);
% Interpolate displacement values at the dvf indices
u_dvf1 = ones(size(ind_def1));
for i = 1:3
    u_grid = squeeze( dvf(:,:,:,1,i) );
    u_dvf1(:,i) = interp3( u_grid, ind_dvf1(:,2), ind_dvf1(:,1), ind_dvf1(:,3) );
end
ind_TLC1 = ind_def1 + u_dvf1;
% Interpolate mask values at those indices
mask_values = interp3( double(TLC_mask), ind_TLC1(:,2), ind_TLC1(:,1), ind_TLC1(:,3) );
mask_values( isnan(mask_values) ) = 0;
% Convert deformed image indices to linear indices
ind_linear = sub2ind( size(def_mask), ind_def(:,1), ind_def(:,2), ind_def(:,3) );
% Set mask values at those linear indices
def_mask(ind_linear) = mask_values;

% Quantify alignment
vol_FRC = sum(FRC_mask > 0.5, 'all');
vol_def = sum(def_mask > 0.5, 'all');
overlap = (FRC_mask>0.5) & (def_mask>0.5);
overlap = sum(overlap,'all');
dice_coeff = 2*overlap / (vol_FRC + vol_def);
fprintf( '\nDice coefficient between registrered TLC mask and FRC mask: %d\n', dice_coeff )
fprintf( 'Ratio of registered mask volume to FRC volume: %d\n', vol_def/vol_FRC )

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
% Registered surface
levelset_def = logic2levelset(def_mask > 0.5);
[F_reg, V_reg] = levelset2isosurface(levelset_def, controlPar);
V_reg = V_reg + origin([2,1,3]) .* [-1,-1,1];

%% Sample displacements onto the TLC surface by inverting the transformation
% Get meshgrid of dvf space
[I_dvf, J_dvf, K_dvf] = ndgrid( 1:size(dvf,1), 1:size(dvf,2), 1:size(dvf,3) );

% Convert dvf meshgrid to RAS coordinates
I_RAS = T_dvf(1,1)*I_dvf + T_dvf(2,1)*J_dvf + T_dvf(3,1)*K_dvf + T_dvf(4,1);
J_RAS = T_dvf(1,2)*I_dvf + T_dvf(2,2)*J_dvf + T_dvf(3,2)*K_dvf + T_dvf(4,2);
K_RAS = T_dvf(1,3)*I_dvf + T_dvf(2,3)*J_dvf + T_dvf(3,3)*K_dvf + T_dvf(4,3);
% Convert RAS grid to FRC grid points
RAS2FRC = T_FRC^(-1);
I_FRC = RAS2FRC(1,1)*I_RAS + RAS2FRC(2,1)*J_RAS + RAS2FRC(3,1)*K_RAS + RAS2FRC(4,1);
J_FRC = RAS2FRC(1,2)*I_RAS + RAS2FRC(2,2)*J_RAS + RAS2FRC(3,2)*K_RAS + RAS2FRC(4,2);
K_FRC = RAS2FRC(1,3)*I_RAS + RAS2FRC(2,3)*J_RAS + RAS2FRC(3,3)*K_RAS + RAS2FRC(4,3);

% Apply displacements to FRC grid to deform it into the TLC grid
I_TLC_def = I_FRC + squeeze(dvf(:,:,:,1,1));
J_TLC_def = J_FRC + squeeze(dvf(:,:,:,1,2));
K_TLC_def = K_FRC + squeeze(dvf(:,:,:,1,3));
% Convert displaced FRC grid to RAS coordinates
I_RAS_def = T_FRC(1,1)*I_TLC_def + T_FRC(2,1)*J_TLC_def + T_FRC(3,1)*K_TLC_def + T_FRC(4,1);
J_RAS_def = T_FRC(1,2)*I_TLC_def + T_FRC(2,2)*J_TLC_def + T_FRC(3,2)*K_TLC_def + T_FRC(4,2);
K_RAS_def = T_FRC(1,3)*I_TLC_def + T_FRC(2,3)*J_TLC_def + T_FRC(3,3)*K_TLC_def + T_FRC(4,3);

% Invert transformation so that it maps back to FRC
dvf_inv = -dvf;

% Interpolate the inverted displacements onto TLC surface
DispArray = zeros(size(V_TLC,1),3);
% [X,Y,Z] to [I,J,K] map:
xyz = [2,1,3];
for i = 1:3
    u_grid = squeeze(dvf_inv(:,:,:,1,i));
    u = interp3( J_RAS_def, I_RAS_def, K_RAS_def, u_grid, V_TLC(:,1), V_TLC(:,2), V_TLC(:,3) );
    DispArray(:,xyz(i)) = u;
end

%% Plot Surfaces
figure()
hold on; 
title('FRC Mask Vs. Registered TLC Mask')
gpatch(F_FRC, V_FRC,'gw'); 
gpatch(F_reg, V_reg,'r'); 
legend("FRC Mask","Registered TLC Mask")
camlight headlight;
drawnow; 
daspect([1,1,1]);
hold off

figure()
hold on; 
title('FRC Mask Vs. Displaced TLC Mask')
gpatch(F_FRC, V_FRC,'gw'); 
gpatch(F_TLC, V_TLC + DispArray,'r'); 
legend("FRC Mask","Registered TLC Mask")
camlight headlight;
drawnow; 
daspect([1,1,1]);
hold off