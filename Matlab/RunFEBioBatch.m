%% Initialize Matlab
clear
clc

%% User Parameters
% The directory to store the generated FEBio input and output files
feb_dir = '..\FEBio\Runs\MeshConvergence';
% Template pattern (template files assumed to be in the run directory) 
template_pattern = '${SIDE}Lung_Lobes_Template.feb';
% .feb input file name pattern
feb_pattern = '${SUBJECT}_${SIDE}Lung_Lobes_tf${tf}.feb';

% The mesh directory and pattern
mesh_dir = '..\FEBio\Meshes\MeshConvergence';
mesh_pattern = '${SUBJECT}_${SIDE}Lung_Lobes_tf${tf}_Mesh.feb';

% Subjects to run (string array)
subjects = "UT172269";

% Model parameters to change in template (1 x P string array)
model_params = ["${SIDE}","${tf}"];
% Values to set those parameters to (M x P string array)
% M is the number of models, P is the number of parameters
model_values = ["Right","1.0"
                "Right","1.1"
                "Right","1.2"];

            
% Set the tasks to perform
generate_feb = true; % Generate .feb input files
run_febio = true; % Run .feb input files

%% Loop through each subject and model
num_subjects = size(subjects,2);
num_params = size(model_params,2);
num_models = size(model_values,1);

% Add mesh_dir to facilitate later edits
addpath(mesh_dir);

for i = 1:num_subjects
    subject = char( subjects(i) );
    
    for j = 1:num_models
        % Get name of the .feb file
        feb_name = replace( feb_pattern, ["${SUBJECT}",model_params], [subjects(i),model_values(j,:)] );
        feb_file = fullfile(feb_dir,feb_name);
        
        % Generate .feb files for the subject
        if generate_feb
            fprintf('\nGenerating .feb file...\n')    
            % Get template file name
            template_name = replace( template_pattern, model_params, model_values(j,:) );
            template_file = fullfile(feb_dir,template_name);
            % Open template file
            fID = fopen(template_file);
            model_txt = fscanf(fID,'%c');
            fclose(fID);
            
            % Edit template to generate new model file
            % Get name of mesh file and make input include it
            mesh_name = replace( mesh_pattern, ["${SUBJECT}",model_params], [subjects(i),model_values(j,:)] );
            mesh_file = which( fullfile(mesh_dir,mesh_name) );
            model_txt = replace(model_txt,'${MESHFILE}',mesh_file);
            % Adjust the value of any other parameters on the template
            model_txt = replace( model_txt, ["${SUBJECT}",model_params], [subjects(i),model_values(j,:)] );        
            % Don't let Matlab mess with formatting
            model_txt = replace(model_txt,'\','\\');
            
            % Save new model file
            fID = fopen(feb_file,'w');
            fprintf(fID,model_txt);
            fclose(fID);      
        end

        % Run .feb files for the subject
        if run_febio    
            fprintf('\nRunning FEBio...\n')

            % Change working directory to the .feb directory
            work_dir = pwd;
            cd(feb_dir);        
            % Run FEBio
            system(['febio3 -i ', feb_name]);        
            % Change back to original working directory
            cd(work_dir);
        end    
    end
end