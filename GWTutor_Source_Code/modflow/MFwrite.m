function [] = MFwrite(struct)
% Author: Andy Banks 2019 - Univeristy of Kansas Dept of Geology 
% GWTutor MODFLOW/MODPATH support library 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Shell to call all modflow input file writing functions

BATwrite(struct);
WELwrite(struct);
DISwrite(struct);
BA6write(struct);
PCGwrite(struct);
OCwrite(struct);
LPFwrite(struct);
RCHwrite(struct);
NAMwrite(struct);


 end