function [] = MFwrite(MFstruct,MPstruct)
% Author: Andy Banks 2019 - Univeristy of Kansas Dept of Geology 
% GWTutor MODFLOW/MODPATH support library 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calls all functions for writing MODPATH input files
MPNAMwrite(MPstruct);
MPBASwrite(MFstruct,MPstruct);
MPSIMwrite(MFstruct,MPstruct);
SLOCwrite(MPstruct);
MPBATwrite(MPstruct);


 end