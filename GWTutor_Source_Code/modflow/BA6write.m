function [] = BA6write(struct)
% consult MODFLOW 2005 documentation for description of file formatting. 
% data is written from input structure (struct) into BA6 file 


%VARIABLES


filename=struct.NAM.filename;
DIM=struct.DIS.DIM;
NLAY=struct.DIS.NLAY;
NCOL=struct.DIS.NCOL;
NROW=struct.DIS.NROW;

X=struct.BA6.X;
IBOUND=struct.BA6.IBOUND;

HNOFLO=struct.BA6.HNOFLO;

%%
filepath=strjoin({pwd,filename,filename},'\');
fname=[filepath,'.BA6'];
fid=fopen(fname,'wt');

r1='#BUILT BY MATLAB ';
r2=['#Transient Simulation, DIM=',num2str(DIM)];
r3='FREE';
fprintf(fid,'%s',r1); fprintf(fid,'\n');
fprintf(fid,'%s',r2); fprintf(fid,'\n');
fprintf(fid,'%s',r3); fprintf(fid,'\n');

IBDspecMF=strcat('I3');
IBDspec=strcat(repmat('%3i',1,NCOL),' \n');
for i=1:NLAY
    r4=['INTERNAL    1  (FREE)   5  IBOUND layer  ',num2str(i)];
    fprintf(fid,'%s',r4); fprintf(fid,'\n');  
    fmt=[repmat('%3d ',1,size(IBOUND(:,:,i),2)-1), '%d\n'];
        
     fprintf(fid,fmt,IBOUND(:,:,i)'); %write IBOUND array 
end

r5=[num2str(HNOFLO),'          HNOFLO'];
fprintf(fid,'%s',r5); fprintf(fid,'\n');


for i=1:NLAY
r6=['INTERNAL  1.0 (FREE)   58  SHEAD layer  ',num2str(i)];%precision 16.9E
fprintf(fid,'%s',r6); fprintf(fid,'\n');
fmt=[repmat('%16.9f ',1,size(X(:,:,i),2)-1), '%16.9f\n'];
fprintf(fid,fmt,X(:,:,i)'); %write X (IC's)
end
status=fclose(fid);
end

