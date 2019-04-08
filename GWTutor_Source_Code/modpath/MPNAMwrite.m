function[] = MPNAMwrite(MPstruct)
% Writes MPNAM -Modpath name file
% consult MODPATH 6  documentation for description of file formatting. 
% data is written from input structure (MPstruct) into MPNAM file 

%WRITES MODPATH MPNAM FILE
filename=MPstruct.MPNAM.filename;
filepath=strjoin({'..',filename},'\');
%Specify and write MPNAM file 


r1=['MPBAS    ',filename,'.mpbas'];
r2=['DIS      ',filename,'.dis'];
r3=['HEAD     00-',filename,'.hed'];
r4=['BUDGET      00-',filename,'.bud'];


filepath=strjoin({pwd,filename,filename},'\');
fname=[filepath,'.mpnam'];

fid=fopen(fname,'wt');

fprintf(fid,'%s',r1); fprintf(fid,'\n');
fprintf(fid,'%s',r2); fprintf(fid,'\n');
fprintf(fid,'%s',r3); fprintf(fid,'\n');
fprintf(fid,'%s',r4); fprintf(fid,'\n');

status=fclose(fid);
end