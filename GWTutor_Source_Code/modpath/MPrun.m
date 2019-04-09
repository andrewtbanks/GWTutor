function [ ] = MPrun(MPstruct)
% Author: Andy Banks 2019 - Univeristy of Kansas Dept of Geology 
% GWTutor MODFLOW/MODPATH support library 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Function executes modflow from filename used in MFwrite

filename=MPstruct.MPNAM.filename;
fname=['00-MP',filename,'.bat&'];
filepath=strjoin({cd,filename,fname},'\');

status=system(filepath);%Execute modpath

end

