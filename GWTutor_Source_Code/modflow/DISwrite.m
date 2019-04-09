function [] = DISwrite(struct)
% Author: Andy Banks 2019 - Univeristy of Kansas Dept of Geology 
% GWTutor MODFLOW/MODPATH support library 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write DIS file - MODFLOW discretization file 
% Consult MODFLOW 2005 documentation for description of file formatting. 
% Data is written from input structure (struct) into DIS file 

%VARIABLES TO SPECIFY
%NLAY,NROW,NCOL,DELR,DELC,TOP,BOT,PERLEN-stress period length, 
%%
filename=struct.NAM.filename;
NLAY=struct.DIS.NLAY;
NROW=struct.DIS.NROW;
NCOL=struct.DIS.NCOL;
NPER=struct.DIS.NPER; %# of stress periods in simulation (=1 for lyapunov)
TrSs=struct.DIS.TrSs; %specifier transient tr or steasy state ss
ITMUNI=struct.DIS.ITMUNI;%time unit (0=undefined)
LENUNI=struct.DIS.LENUNI;%length unit (0=undefined)
DELR=struct.DIS.DELR;% cell row spacing 
DELC=struct.DIS.DELC; % cell column spacing 
TOP=struct.DIS.TOP;% top aquifer elevation
BOT=struct.DIS.BOT; % bottom aquifer elevation
PERLEN=struct.DIS.PERLEN;%stress period length
NSTP=struct.DIS.NSTP;%# of timesteps in period
TSMULT=struct.DIS.TSMULT;% multiplier for length of sucessive steps (keep 1.0 for constant step size.... probably doesnt matter if NSTP=1)
LAYCBD=struct.DIS.LAYCBD;% flag (1) indicating whether the layer has quasi 3-d confining bed below (must be 0 for bottom layer
%%
filepath=strjoin({pwd,filename,filename},'\');
fname=[filepath,'.DIS'];
fid=fopen(fname,'wt');

r1=['#Discretization input data for ',filename,' --Transient'];
r2=['         ',num2str(NLAY),'        ',num2str(NROW),'        ',num2str(NCOL),'   ',num2str(NPER),'   ',num2str(ITMUNI),'   ',num2str(LENUNI),'  NLAY,NROW,NCOL,NPER,ITMUNI (0=undefined),LENUNI (0= undefined)'];
r3=num2str(LAYCBD);
fprintf(fid,'%s',r1); fprintf(fid,'\n');
fprintf(fid,'%s',r2); fprintf(fid,'\n');
fprintf(fid,'%s',r3); fprintf(fid,'\n');

r4=['INTERNAL 1.0 (FREE)   '];
fmt=[repmat('%16.9f ',1,size(DELR,2)-1), '%16.9f\n'];
fprintf(fid,'%s',r4); fprintf(fid,'\n');
fprintf(fid,fmt,DELR');

r5=['INTERNAL 1.0 (FREE)  '];
fprintf(fid,'%s',r5); fprintf(fid,'\n');
fmt=[repmat('%16.9f ',1,size(DELC,2)-1), '%16.9f\n'];
fprintf(fid,fmt,DELC');

r6=['INTERNAL 1.0 (FREE) '];
fprintf(fid,'%s',r6); fprintf(fid,'\n');
fmt=[repmat('%16.9f ',1,size(TOP,2)-1), '%16.9f\n'];
fprintf(fid,fmt,TOP'); 

for i=1:size(BOT,3)
r7=['INTERNAL 1.0 (FREE)   '];
fmt=[repmat('%16.9f ',1,size(BOT(:,:,i),2)-1), '%16.9f\n'];
fprintf(fid,'%s',r7); fprintf(fid,'\n');
fprintf(fid,fmt,BOT(:,:,i)'); 
end

for i=1:NPER
r8=[num2str(PERLEN(i)),'    ',num2str(NSTP(i)),'    ',num2str(TSMULT(i)),'  ',cell2mat(TrSs(i))];%'            PERLEN NSTP,TSMULT,Ss/tr 
fprintf(fid,'%s',r8); fprintf(fid,'\n');
end

status=fclose(fid);
end

