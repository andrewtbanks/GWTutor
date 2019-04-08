function [] = MFwrite(MFstruct,MPstruct)
% call all functions for writing MODPATH input files
MPNAMwrite(MPstruct);
MPBASwrite(MFstruct,MPstruct);
MPSIMwrite(MFstruct,MPstruct);
SLOCwrite(MPstruct);
MPBATwrite(MPstruct);


 end