% A script for checking how much the transformed TLC mask lines up with the
% FRC mask

%% Initialize Matlab
clear
clc
tic
%% User Parameters
subject = 'UT172269';
side = 'left';

% TLC Mask
mask_dir_pattern = 'X:\FissureIntegrity\IntegrityNet_Data\${SUBJECT}\seg';
EI_name_pattern = '${SUBJECT}_V1_INSP_resampled.lobe.nii.gz';
% FRC Mask
EE_name_pattern = '${SUBJECT}_V1_EXP_resampled.lobe.nii.gz';
% DVF Data
dvf_dir_pattern = 'X:\segerard\${SITE}\${SUBJECT}\registration\exp_to_insp\${SIDE}';
dvf_name_pattern = 'Disp.nii.gz';

% Mask segments to use
if strcmp(side,'left')
    seg_maskIDs = [8,16];
elseif strcmp(side,'right')
    seg_maskIDs = [32,64,128];
end
%% Open mask and dvf files and metadata
% Complete patterns
site = subject(1:2);
mask_dir = replace( mask_dir_pattern, {'${SUBJECT}','${SITE}','${SIDE}'}, {subject,site,side} );
EI_name = replace( EI_name_pattern, {'${SUBJECT}','${SITE}','${SIDE}'}, {subject,site,side} );
EE_name = replace( EE_name_pattern, {'${SUBJECT}','${SITE}','${SIDE}'}, {subject,site,side} );
dvf_dir = replace( dvf_dir_pattern, {'${SUBJECT}','${SITE}','${SIDE}'}, {subject,site,side} );
dvf_name = replace( dvf_name_pattern, {'${SUBJECT}','${SITE}','${SIDE}'}, {subject,site,side} );

% TLC
EI_file = fullfile(mask_dir,EI_name);
EI_info = niftiinfo(EI_file);
EI_mask = niftiread(EI_info);
T_EI = EI_info.Transform.T;
EI_size = size(EI_mask);

% FRC
EE_file = fullfile(mask_dir,EE_name);
EE_info = niftiinfo(EE_file);
EE_mask = niftiread(EE_info);
T_EE = EE_info.Transform.T;
EE_size = size(EE_mask);

% DVF
dvf_file = fullfile(dvf_dir,dvf_name);
dvf_info = niftiinfo(dvf_file);
dvf = niftiread(dvf_info);
T_dvf = dvf_info.Transform.T;
dvf_size = size(dvf);

%% Get deformed mask on TLC grid using DVF
reg_mask = zeros(size(EI_mask));
% Get all deformed mask indices in one big array
[I_EI, J_EI, K_EI] = ndgrid( 1:size(reg_mask,1), 1:size(reg_mask,2), 1:size(reg_mask,3) );
ind_def = [ reshape(I_EI,[],1), reshape(J_EI,[],1), reshape(K_EI,[],1) ];
ind_def1 = [ind_def, ones(size(ind_def,1),1)];
% Convert those indices into dvf indices
ind_dvf1 = ind_def1 * T_EI * T_dvf^(-1);
% Interpolate displacement values at the dvf indices
u_dvf1 = ones(size(ind_def1));
for i = 1:3
    u_grid = squeeze( dvf(:,:,:,1,i) );
    u_dvf1(:,i) = interp3( u_grid, ind_dvf1(:,2), ind_dvf1(:,1), ind_dvf1(:,3) );
end
% Convert displaced indices in dvf space to EE indices
%ind_FRC1 = (ind_dvf1 + u_dvf1) * T_dvf * T_EE^(-1);
ind_EE1 = ind_def1 + u_dvf1;
% Interpolate mask values at those indices
mask_values = interp3( double(EE_mask), ind_EE1(:,2), ind_EE1(:,1), ind_EE1(:,3) );
mask_values( isnan(mask_values) ) = 0;
% Convert deformed image indices to linear indices
ind_linear = sub2ind( size(reg_mask), ind_def(:,1), ind_def(:,2), ind_def(:,3) );
% Set mask values at those linear indices
reg_mask(ind_linear) = mask_values;

%% Slice viewer
% figure()
% sliceViewer(EI_mask)
% title('INSP Mask')
% 
% figure()
% sliceViewer(EE_mask)
% title('EXP Mask')
% 
% figure()
% sliceViewer(def_mask)
% title('Deformed Mask')

% Quantify alignment
vol_EE = sum( ismember(EI_mask,seg_maskIDs), 'all');
vol_def = sum( ismember(reg_mask,seg_maskIDs), 'all');
overlap = ismember(EI_mask,seg_maskIDs) & ismember(reg_mask,seg_maskIDs);
overlap = sum(overlap,'all');
dice_coeff = 2*overlap / (vol_EE + vol_def);
fprintf( '\nDice coefficient between registrered TLC mask and FRC mask: %d\n', dice_coeff )
fprintf( 'Ratio of registered mask volume to FRC volume: %d\n', vol_def/vol_EE )

%% Create surfaces for comparison
origin = T_EE(4,1:3);
controlPar.contourLevel = 0;
controlPar.voxelSize = [1 1 1];
controlPar.nSub = [4 4 4];
controlPar.capOpt = 1;

% TLC surface
levelset_EI = logic2levelset( ismember(EI_mask,seg_maskIDs) );
[F_EI, V_EI] = levelset2isosurface(levelset_EI, controlPar);
V_EI = V_EI + origin([2,1,3]) .* [-1,-1,1];
% FRC surface
levelset_EE = logic2levelset( ismember(EE_mask,seg_maskIDs) );
[F_EE, V_EE] = levelset2isosurface(levelset_EE, controlPar);
V_EE = V_EE + origin([2,1,3]) .* [-1,-1,1];
% Deformed surface
levelset_def = logic2levelset( ismember(reg_mask,seg_maskIDs) );
[F_reg, V_reg] = levelset2isosurface(levelset_def, controlPar);
V_reg = V_reg + origin([2,1,3]) .* [-1,-1,1];

%% Interpolate displacments onto TLC surface to compare displaced and FRC
% Interpolate displacements
u = SampleDispField(V_EI,dvf_file);
V_def = V_EI + u;
F_def = F_EI;

%% Plot surfaces
figure(); 
hold on; 
title('INSP Vs. EXP surface')
gpatch(F_EI, V_EI,'g'); 
gpatch(F_EE, V_EE,'r');
camlight headlight;
drawnow; 
legend("INSP Mask","EXP Mask")
daspect([1,1,1]);
hold off

figure(); 
hold on; 
title('INSP Vs. Registered EXP surface')
gpatch(F_EI, V_EI,'g'); 
gpatch(F_reg, V_reg,'r'); 
camlight headlight;
legend("INSP Mask","Registered EXP Mask")
drawnow; 
daspect([1,1,1]);
hold off

figure(); 
hold on; 
title('EXP vs. Displacement Boundary Conditions')
gpatch(F_EE, V_EE,'g');
gpatch(F_def, V_def,'r');
camlight headlight;
legend("EXP Mask","INSP Mask with BC's")
drawnow; 
daspect([1,1,1]);
hold off

toc