function [] = MFwrite(struct)
%% shell to call all modflow input file writing functions
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