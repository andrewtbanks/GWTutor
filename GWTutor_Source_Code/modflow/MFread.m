function [Xlast,XNEW,BUDNEW] = MFread(struct)

% retrieve and format modflow output
% reads heads and budgt, formats into array then returns the final head
% distribution (Xlast), the heads at evey timestep (XNEW) and the budget at
% every timestep (BUDNEW) 

%read  new heads from .SHD file using dlmread 
filename=struct.NAM.filename;
NSTP=struct.DIS.NSTP;
NPER=struct.DIS.NPER;
RETURNPER=struct.OC.RETURNPER;
RETURNSTEP=struct.OC.RETURNSTEP;

NCOL=struct.DIS.NCOL;
NROW=struct.DIS.NROW;
NLAY=struct.DIS.NLAY;
DIM=struct.DIS.DIM;
fname=['00-',filename,'.SHD'];
fname=['00-',filename,'.HED'];
fname2=['00-',filename,'.BUD'];
filepath=strjoin({pwd,filename,fname},'\');
filepath2=strjoin({pwd,filename,fname2},'\');

%%%% begin reading


% check that modflow is done running before opening .SHD and .BUD
IDpath=strsplit(pwd,'\');
IDpath(end+1)={filename};
IDpath(end+1)={strcat(filename,'_modflowID.txt')};
IDpath=strjoin(IDpath,'\');

IDexist = 0;
while IDexist == 0
   pause(1) 
    if exist(IDpath,'file') == 2
        IDexist = 1;
    end
end
exist(IDpath,'file')

fid=fopen(filepath);
fid2=fopen(filepath2);

temp=fread(fid,'float');
temp2=fread(fid2,'float');
BUDNEW=temp2;

cnt=11;
layercnt=floor(DIM/NLAY);
    for k=1:NPER
        for i=1:NSTP
            for j=1:NLAY
                XNEW(:,j,i,k)=temp(cnt+1:cnt+layercnt);
                cnt=cnt+layercnt+11;
            end
        end
     end
 Xlast=XNEW(:,:,NSTP,NPER); %return head from last step in period    
    
status=fclose('all');%close all files to avoid problems 
end

