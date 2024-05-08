Project Description:  
An automated pipeline for converting segmented lung CT images to FEBio models. Voxel-wise displacement field images are required as a secondary input.


**Folder Descriptions**  
Segmentation, voxel-wise displacement fields, or final FEBio input and output files are ignored by Git and will not appear in the repository. That said, there are preferred locations for storing this data in the local version of the repository as descirbed below:
- Matlab: Contains all Matlab scripts and functions used by the pipeline.
  - Obselete: Matlab scripts that have been replaced by newer scripts, but may be worth keeping around. Not documented below in **Matlab Script Descriptions**.
  - Unused: Experimental Matlab scripts that are unused by the main scripts. Not documented below in **Matlab Script Descriptions**.
- FEBio: Preferred location for storing FEBio file templates, meshes, and outputs. Non-template FEBio input and output files are ignored by Git.
  - Meshes: Preferred location for .feb files containing subject-specific data (e.g. meshes and data stored on the meshes).
  - Runs: Preferred location for generic template .feb files (which produce a full model when a mesh .feb file is included) and for storing the output of FEBio runs.
- Segmentations: Preferred location for segmentation data. Everything in this folder is ignored by Git.
- DispFields: Preferred location for voxel-wise displacement field data. Everything in this folder is ignored by Git.
- Local: Place to store other miscellaneous data and results. Everything in this folder is ignored by Git.


**Matlab Script Descriptions**  
Main scripts: These are run by the user.


Supporting functions: These are called by main scripts.

**Requirements**  
The pipeline requires the Matlab Image Processing Toolbox and the GIBBONCode library. 