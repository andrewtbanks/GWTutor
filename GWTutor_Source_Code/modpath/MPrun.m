function [ ] = MPrun(MPstruct)
%executes modflow from filename used in MFwrite

filename=MPstruct.MPNAM.filename;
fname=['00-MP',filename,'.bat&'];
filepath=strjoin({cd,filename,fname},'\');

status=system(filepath);%Execute modpath

end

