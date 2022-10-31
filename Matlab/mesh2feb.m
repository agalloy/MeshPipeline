

function mesh2feb(feb_file,feb_template,inStruct)
%% Parse inStruct
    % Required fieds
    % Cell array containing Node positions for each region
    if isfield(inStruct,'NodeCells')
        NodeCells = inStruct.NodeCells;
    else
        error('Node data required to generate .feb file.')
    end
    % Cell array containing element connectivities for each region
    if isfield(inStruct,'ElementCells')
        ElementCells = inStruct.ElementCells;
    else
        error('Element data required to generate .feb file.')
    end
    % Optional fields
    % String array of model region names
    if isfield(inStruct,'model_regions')
        model_regions = inStruct.model_regions;
    else
        model_regions = repmat( "region#", 1, length(ElementCells) );
        model_regions = strrep( model_regions, '#', string(1:length(ElementCells)) );
    end
    % The directory containing displacement vector field info
    if isfield(inStruct,'disp_dir')
        disp_dir = inStruct.disp_dir;
    else
        disp_dir = '';
    end
    % The thickness for shell elements
    if isfield(inStruct,'shell_thickness')
        shell_thickness = inStruct.shell_thickness;
    else
        shell_thickness =  0.01;
    end    
    
%% Open the template .feb file
    fID = fopen(feb_template);
    feb_str = fscanf(fID,'%c');
    fclose(fID);
    
%% Loop through each mesh region generating their respective text
    % Initialize global node and element identifier arrays
    nID_offset = 0;
    eID_offset = 0;
    nID = cell(size(NodeCells));
    eID = cell(size(ElementCells));
    % Loop through each 
    for i = 1:length(model_regions)
        region = char(model_regions(i));
        NodeArray = NodeCells{i};
        ElementArray = ElementCells{i};
        
        % Get global node and element identifiers for the region
        nID{i} = (1:size(NodeArray,1))' + nID_offset;
        eID{i} = (1:size(ElementArray,1))' + eID_offset;
        % Increment nID and eID offsets
        nID_offset = nID_offset + size(NodeArray,1);
        eID_offset = eID_offset + size(ElementArray,1);
        
        % Assemble region structure
        regStruct = struct();
        regStruct.NodeArray = NodeArray;
        regStruct.nID = nID{i};
        regStruct.ElementArray = ElementArray;
        regStruct.eID = eID{i};
        regStruct.name = region;
        regStruct.mat = ['Mat',num2str(i)];
        
        % Process region differently depending on whether it is a shell or
        % solid region
        if size(ElementArray,2) == 4
            % Add the solid domain to the .feb file
            feb_str = febSolid(feb_str, regStruct);
        elseif size(ElementArray,2) == 3
            % Complete region structure
            regStruct.shell_thickness = shell_thickness;
            % Add the shell domain to the .feb file
            feb_str = febShell(feb_str, regStruct);
        else
            error('Unrecognized element type.')
        end
    end

%% Generate surface pairs for each mesh region
    surface_pairs = nchoosek(1:length(model_regions),2);
    for i = 1:size(surface_pairs,1)
        % Get names of primary and secondary surface
        psurf = char( model_regions(surface_pairs(i,2)) );
        ssurf = char( model_regions(surface_pairs(i,1)) );
        
        % Add surface pair to .feb text
        sp_head = sprintf('\t\t<SurfacePair name="%s-%s">\r\n',psurf,ssurf);
        sp_body = sprintf('\t\t\t<primary>%s</primary>\r\n\t\t\t<secondary>%s</secondary>\r\n',psurf,ssurf);
        sp_foot = sprintf('\t\t</SurfacePair>\r\n');
        sp_sect = [sp_head,sp_body,sp_foot];
        feb_str = insertBefore(feb_str,sprintf('\t</Mesh>\r\n'),sp_sect);
    end
%% Write .feb file to the supplied filepath 
    fID = fopen(feb_file,'w');
    fprintf(fID,feb_str);
    fclose(fID);
end