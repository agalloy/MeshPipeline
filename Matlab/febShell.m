

function feb_str = febShell(feb_str, regStruct)
%% Parse regStruct
    % Get required fields
    NodeArray = regStruct.NodeArray;
    ElementArray = regStruct.ElementArray;
    name = regStruct.name;
    mat = regStruct.mat;
    shell_thickness = regStruct.shell_thickness;
    
    % Get optional fields
    if isfield(regStruct,'nID')
        nID = regStruct.nID;
    else
        nID = (1:size(NodeArray,1))';
    end
    if isfield(regStruct,'eID')
        eID = regStruct.eID;
    else
        eID = (1:size(ElementArray,1))';
    end
    
%% Write Nodes section
    node_head = sprintf('\t\t<Nodes name="%s">\r\n',name);
    node_foot = sprintf('\t\t</Nodes>\r\n');
    
    node_data = [ nID, NodeArray ];    
    node_body = sprintf('\t\t\t<node id="%d">%f,%f,%f</node>\r\n',node_data');
    
    node_sect = [node_head,node_body,node_foot];
    
%% Write Elements section
    % Get the global element array
    EA_global = nID(ElementArray);
    
    el_head = sprintf('\t\t<Elements type="tri3" name="%s">\r\n',name);
    el_foot = sprintf('\t\t</Elements>\r\n');
    
    el_data = [ eID, EA_global];
    el_body = sprintf('\t\t\t<elem id="%d">%d,%d,%d</elem>\r\n',el_data');
    
    el_sect = [el_head,el_body,el_foot];
    
%% Write Surface section
    surf_head = sprintf('\t\t<Surface name="%s_surface">\r\n',name);
    surf_foot = sprintf('\t\t</Surface>\r\n');
    
    surf_data = [ (1:size(EA_global,1))', EA_global ];
    surf_body = sprintf('\t\t\t<tri3 id="%d">%d,%d,%d</tri3>\r\n',surf_data');
    
    surf_sect = [surf_head,surf_body,surf_foot];
    
%% Write ShellDomain section
    sd_sect = sprintf('\t\t<ShellDomain name="%s" mat="%s"/>\r\n',name,mat);
    
%% Write ElementData (thickness) section
    ed_head = sprintf('\t\t<ElementData var="shell thickness" elem_set="%s">\r\n',name);
    ed_foot = sprintf('\t\t</ElementData>\r\n');
    
    ed_data = [ eID, ones(length(ElementArray),3)*shell_thickness];
    ed_body = sprintf('\t\t\t<e lid="%d">%f,%f,%f</e>\r\n',ed_data');
    
    ed_sect = [ed_head,ed_body,ed_foot];

%% Insert it all into .feb string
    feb_str = insertBefore(feb_str,sprintf('\t</Mesh>\r\n'),[node_sect,el_sect,surf_sect]);
    feb_str = insertBefore(feb_str,sprintf('\t</MeshDomains>\r\n'),sd_sect);
    feb_str = insertBefore(feb_str,sprintf('\t</MeshData>\r\n'),ed_sect);
    
end