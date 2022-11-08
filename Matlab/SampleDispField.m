% SampleDispField: Sample a displacement field for the desired subject at
% the given points
% Created 11/08/2022 by Adam Galloy
%
% Inputs:
%    X = An [N X 3] array of coordinates for the points to be sampled
%    disp_pattern = A file pattern pointing to the displacement data
% Outputs:
%    disp = An [N X 3] array of displacements located at each desired point

function disp = SampleDispField(X,disp_pattern)
    % Initialize displacement array
    disp = nan( size(X,1), 3 );
    
    % Get model bounds (plus a buffer of 5 mm)
    x_min = min(X(:,1)) - 5;
    x_max = max(X(:,1)) + 5;
    y_min = min(X(:,2)) - 5;
    y_max = max(X(:,2)) + 5;
    z_min = min(X(:,3)) - 5;
    z_max = max(X(:,3)) + 5;
    
    % Coordinate axes to loop through
    axes = {'x','y','z'};
    
    % Loop through each axis sampling disp data
    for i = 1:numel(axes)
        % Get the displacement vector field (dvf) for the given axis
        dvf_path = replace(disp_pattern,'${AXIS}',axes{i});
        % Read metadata
        dvf_info = analyze75info(dvf_path);
        dvf_spacing = dvf_info.PixelDimensions(1:3);
        % Load dvf
        dvf = analyze75read(dvf_info);
        dvf_size = size(dvf);
        
        % Convert the voxel centers to a set of points
        ind_i = 1:dvf_size(1);
        ind_j = 1:dvf_size(2);
        ind_k = 1:dvf_size(3);       
        Px = double( (ind_j-1) * dvf_spacing(2) );
        Py = double( (ind_i-1) * dvf_spacing(1) );
        Pz = double( (ind_k-1) * dvf_spacing(3) );
        Pu = dvf;
        
        % Remove points far away from ROI to reduce computing time
        %P_in = (Px < x_max) & (Px > x_min); 
        %P_in = P_in & (Py < y_max) & (Py > y_min);
        %P_in = P_in & (Pz < z_max) & (Pz > z_min);
        %Px = Px(P_in);
        %Py = Py(P_in);
        %Pz = Pz(P_in);
        %Pu = Pu(P_in);
                
        % Get displacements at query points with linear interpolation
        disp(:,i) = interp3(Px,Py,Pz,Pu,X(:,1),X(:,2),X(:,3),'linear');
    end
end