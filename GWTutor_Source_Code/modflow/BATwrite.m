function [] = BATwrite(struct)
% Author: Andy Banks 2019 - Univeristy of Kansas Dept of Geology 
% GWTutor MODFLOW/MODPATH support library 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Writes .bat file to execute MODFLOW model 


filename=struct.NAM.filename; %name of batch file

pause=struct.BAT.PAUSE;

%get directory of this folder
CurDir = strsplit(pwd,filesep);
CurDir(end+1)={'modflow'};
CurDir=strjoin(CurDir,filesep);

%directory to write modflow files to 
DirOut = strsplit(pwd,filesep);
DirOut(end+1)={filename};
DirOut=strjoin(DirOut,filesep);

NewDir=filename;
ModelDir=strjoin({pwd,NewDir},filesep);

if exist(ModelDir)~=7
    mkdir(ModelDir)
end

NamPath=strjoin({pwd,NewDir,[filename,'.nam']},filesep);

IDpath=strsplit(pwd,filesep);
IDpath(end+1)={filename};
IDpath(end+1)={strcat(filename,'_modflowID.txt')};
IDpath=strjoin(IDpath,filesep);

mfPathNew=strjoin({pwd,'mf2005.exe'},filesep);


%text in NAM file
r1=['del "',IDpath,'"']; % delete current ID file
r2=['cd /d ',ModelDir]; % set current directory to 
%r3=['mf2005.exe  ',filename,'.nam']; %location of NAM file and 
r3=[mfPathNew,'  ..\',filename,filesep,filename,'.nam'];
r4=['break>"',IDpath,'"'];
r5=pause;
 
fname = strjoin({DirOut,['00-MF',filename,'.bat']},filesep);

fid=fopen(fname,'wt');
fprintf(fid,'%s',r1); fprintf(fid,'\n');
fprintf(fid,'%s',r2); fprintf(fid,'\n');
fprintf(fid,'%s',r3); fprintf(fid,'\n');
fprintf(fid,'%s',r4); fprintf(fid,'\n');
fprintf(fid,'%s',r5); fprintf(fid,'\n');

status=fclose(fid);
end