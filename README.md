Project Description:  
An automated pipeline for converting segmented lung CT images to FEBio models. Voxel-wise displacement field images are required as a secondary input.

**Folder Descriptions**  
Segmentation, voxel-wise displacement fields, or final FEBio input and output files are ignored by Git and will not appear in the repository. That said, the preferred location for storing this data is the Local directory as descirbed below:
- Matlab: Contains all Matlab scripts and functions used by the pipeline.
  - Obselete: Matlab scripts that have been replaced by newer scripts, but may be worth keeping around.
  - Experimental: Undocumented experimental Matlab scripts that are unused by the main scripts.
- FEBio: Preferred location for storing FEBio file templates, meshes, and outputs. Non-template FEBio input and output files are ignored by Git.
  - Meshes: Preferred location for .feb files containing subject-specific data (e.g. meshes and data stored on the meshes).
  - Runs: Preferred location for generic template .feb files (which produce a full model when a mesh .feb file is included) and for storing the output of FEBio runs.
- Local: Place to store data and results. Everything in this folder is ignored by Git.

**Requirements**  
The pipeline requires the Matlab Image Processing Toolbox and the GIBBONCode library. 
