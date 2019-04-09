function[]=NAMwrite(struct)
% Author: Andy Banks 2019 - Univeristy of Kansas Dept of Geology 
% GWTutor MODFLOW/MODPATH support library 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Writes MODFLOW name file 
% Consult MODFLOW 2005 documentation for description of file formatting. 
% Data is written from input structure (struct) into NAM file 


filename=struct.NAM.filename;
%filepath=strjoin({pwd,filename},'\');
filepath=strjoin({'..',filename},'\');

%Specify and write NAM file 
r1='# NAME file for lyap test case';
r2='# This test case has one layer and pumping.' ;
r3=['LIST                  9 ',filepath,'\','MF-',filename,'.lst'];
r4=['BAS6                 75 ',filepath,'\',filename,'.ba6'];
r5=['LPF                   7 ',filepath,'\',filename,'.lpf'];
r6=['DIS                   8 ',filepath,'\',filename,'.dis'];
r7=['PCG                  13 ',filepath,'\',filename,'.pcg'];
r8=['OC                   14 ',filepath,'\',filename,'.oc'];
r9=['WEL                  16 ',filepath,'\',filename,'.wel'];
r10=['RCH                  17 ',filepath,'\',filename,'.rch'];
%r11=['DATA                 58 ',filepath,'\','00-',filename,'.shd'];
r12=['DATA(BINARY)                 15 ',filepath,'\','00-',filename,'.hed'];
r13=['DATA(BINARY)                 11 ',filepath,'\','00-',filename,'.bud'];



filepath=strjoin({pwd,filename,filename},'\');
fname=[filepath,'.NAM'];
fid=fopen(fname,'wt');

fprintf(fid,'%s',r1); fprintf(fid,'\n');
fprintf(fid,'%s',r2); fprintf(fid,'\n');
fprintf(fid,'%s',r3); fprintf(fid,'\n');
fprintf(fid,'%s',r4); fprintf(fid,'\n');
fprintf(fid,'%s',r5); fprintf(fid,'\n');
fprintf(fid,'%s',r6); fprintf(fid,'\n');
fprintf(fid,'%s',r7); fprintf(fid,'\n');
fprintf(fid,'%s',r8); fprintf(fid,'\n');
fprintf(fid,'%s',r9); fprintf(fid,'\n');
fprintf(fid,'%s',r10); fprintf(fid,'\n');
% fprintf(fid,'%s',r11); fprintf(fid,'\n');
fprintf(fid,'%s',r12); fprintf(fid,'\n');
fprintf(fid,'%s',r13); fprintf(fid,'\n');
status=fclose(fid);
end
