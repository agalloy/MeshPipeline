% SampleDispField: Sample a displacement field for the desired subject at
% the given points
% Created 11/08/2022 by Adam Galloy
%
% Inputs:
%    X = An [N X 3] array of coordinates for the points to be sampled
%    disp_pattern = A file pattern pointing to the displacement data
% Outputs:
%    disp = An [N X 3] array of displacements located at each desired point

function dispArray = SampleDispField(X,disp_pattern)
    % Initialize displacement array
    dispArray = nan( size(X,1), 3 );
    
    % Check if disp field components are together in one file or seperate
    if ~contains(disp_pattern,'${AXIS}')
        % Open full disp file
        dvf_info = niftiinfo(disp_pattern);
        dvf_full = niftiread(disp_pattern);
        dvf_spacing = dvf_info.PixelDimensions(1:3);
        together = true;        
        % Coordinate axes to loop through
        axes = {'x','y','z'};
        axes_ind = [2,1,3];
    else
        % Coordinate axes to loop through
        axes = {'x','y','z'};
        axes_ind = [2,1,3];
        together = false;
    end
    
    % Loop through each axis sampling disp data
    for i = 1:numel(axes)
        if ~together
            % Get the displacement vector field (dvf) for the given axis
            dvf_path = replace(disp_pattern,'${AXIS}',axes{i});
            % Read metadata
            dvf_info = analyze75info(dvf_path);
            dvf_spacing = dvf_info.PixelDimensions(1:3);
            % Load dvf for the current axis
            dvf = analyze75read(dvf_info);
            dvf_size = size(dvf);
        else
            % Get only the dvf for the current axis
            dvf = dvf_full(:,:,:,1,i);
            dvf_size = size(dvf);
        end
        
        % Convert the voxel centers to a set of points
        ind_i = 1:dvf_size(1);
        ind_j = 1:dvf_size(2);
        ind_k = 1:dvf_size(3);       
        Px = double( (ind_j-1) * dvf_spacing(2) );
        Py = double( (ind_i-1) * dvf_spacing(1) );
        Pz = double( (ind_k-1) * dvf_spacing(3) );
        Pu = dvf;

        % Get displacements at query points with linear interpolation
        dispArray(:,axes_ind(i)) = interp3(Px,Py,Pz,Pu,X(:,1),X(:,2),X(:,3),'linear');
    end
end