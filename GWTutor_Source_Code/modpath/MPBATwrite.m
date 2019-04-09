function [ output_args ] = MPBATwrite( MPstruct )
% Author: Andy Banks 2019 - Univeristy of Kansas Dept of Geology 
% GWTutor MODFLOW/MODPATH support library 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Writes batch file to execute MODPATH model


filename=MPstruct.MPNAM.filename; %name of batch file
pause=MPstruct.MPBAT.PAUSE;
%get directory of this folder
CurDir = strsplit(pwd,filesep);
CurDir(end+1)={'modpath'};
CurDir=strjoin(CurDir,filesep);

%directory to write modflow files to 
DirOut = strsplit(pwd,filesep);
DirOut(end+1)={filename};
DirOut=strjoin(DirOut,filesep);

NewDir=filename;
ModelDir=strjoin({pwd,NewDir},filesep);
NamPath=strjoin({pwd,NewDir,[filename,'.mpsim']},filesep);
IDpath=strsplit(pwd,filesep);
IDpath(end+1)={filename};
IDpath(end+1)={strcat(filename,'_modpathID.txt')};
IDpath=strjoin(IDpath,filesep)


mpPath=strjoin({CurDir,'Mpath7.exe'},filesep);
mpPathNew=strjoin({pwd,'Mpath7.exe'},filesep);


%text in NAM file
 r1=['del ',IDpath];
 r2=['cd /d ',ModelDir];
 r3=[mpPathNew,' ..\',filename,filesep,filename]; %location of NAM file and
 r4=['break>"',IDpath];
 r5=pause;
 
fname = strjoin({DirOut,['00-MP',filename,'.bat']},filesep);

fid=fopen(fname,'wt');
fprintf(fid,'%s',r1); fprintf(fid,'\n');
fprintf(fid,'%s',r2); fprintf(fid,'\n');
fprintf(fid,'%s',r3); fprintf(fid,'\n');
fprintf(fid,'%s',r4); fprintf(fid,'\n');
fprintf(fid,'%s',r5); fprintf(fid,'\n');
status=fclose(fid);

end

