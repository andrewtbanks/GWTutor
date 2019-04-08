function [ ] = MFrun(struct)
%executes modflow from filename used in MFwrite and batch file from
%BATwrite

filename=struct.NAM.filename;
fname=['00-MF',filename,'.bat&'];
filepath=strjoin({cd,filename,fname},'\');

status=system(filepath);%Execute model

end

