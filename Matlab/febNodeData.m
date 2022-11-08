

function feb_str = febNodeData(feb_str, regStruct)
%% Parse regStruct
    % Get required fields
    NodeData = regStruct.NodeData;
    NodeVars = regStruct.NodeVars;
    name = regStruct.name;
    
%% Loop through each node variable and add the node data to the feb_str
    nd_foot = sprintf('\t\t</NodeData>\r\n');
    % Loop through each node data variable and create a section for it
    num_var = numel(NodeVars);
    for i = 1:num_var
        % Header of node data section for the current variable
        nd_head = sprintf('\t\t<NodeData name="%s" data_type="scalar" node_set="%s">\r\n',NodeVars{i},name);
        % Body of node data section for the current variable
        nd_body = sprintf('\t\t\t<node lid="%d">%f</node>\r\n', [(1:size(NodeData,1))',NodeData(:,i)]');
        % Assemble node data section for the current variable
        nd_sect = [nd_head,nd_body,nd_foot];
        
        % Edit feb_str
        feb_str = insertBefore(feb_str,sprintf('\t</MeshData>\r\n'),nd_sect);
    end
end