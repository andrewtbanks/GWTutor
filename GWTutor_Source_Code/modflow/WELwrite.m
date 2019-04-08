function [] = WELwrite(struct)
% consult MODFLOW 2005 documentation for description of file formatting. 
% data is written from input structure (struct) into WEL file 

%filename=first part of file name (ex for test.NAM input filename='test')
%pos=well position (symmeptric ie input is at position (pos,pos); 

%VARIBLES
filename=struct.NAM.filename;
Q=struct.WEL.Q; %pumpage at position specified by pos
MXACTW=struct.WEL.MXACTW;%maximum number of wells in use during any stress period (=1 for now);
LAYER=struct.WEL.LAYER;%model layer the contains well
ROW=struct.WEL.ROW;%model row that contains the well
COLUMN=struct.WEL.COLUMN;%model column that conatins the well
NPER=struct.DIS.NPER;

%%
filepath=strjoin({pwd,filename,filename},'\');
fname = [filepath,'.WEL'];
fid=fopen(fname,'wt');
r1=[num2str(MXACTW),'        11                  MXACTW IWELCB'];
fprintf(fid,'%s',r1); fprintf(fid,'\n');


 
for i=1:NPER
r2=[num2str(MXACTW),'         0                 ITMP NP '];
fprintf(fid,'%s',r2); fprintf(fid,'\n');
    for j=1:MXACTW
        r3=['         ',num2str(LAYER(i,j)),'         ',num2str(ROW(i,j)),'         ',num2str(COLUMN(i,j)),'      ',num2str(Q(i,j))];
        fprintf(fid,'%s',r3); fprintf(fid,'\n');
    end
    
 end   

status=fclose(fid);
end