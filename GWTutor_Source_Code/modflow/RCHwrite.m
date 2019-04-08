function [struct ] = RCHwrite( struct )
% Write RCH file - recharge package
% consult MODFLOW 2005 documentation for description of file formatting. 
% data is written from input structure (struct) into RCH file 
filename=struct.NAM.filename;
NPRCH=struct.RCH.NPRCH;%in.nprch;
NRCHOP=struct.RCH.NRCHOP; %recharge option code (1== recharge only to top grid layer)
IRCHB=struct.RCH.IRCHB; %flag to save cell be cell flow terms
INRECH=struct.RCH.INRECH; %flag indigating how recharge rates are read; (1 mean read for each stress period) 
RECH=struct.RCH.RECH; %read array of recharge values for each stress period 
NPER=struct.DIS.NPER;

%%
filepath=strjoin({pwd,filename,filename},'\');
fname=[filepath,'.RCH'];
fid=fopen(fname,'wt');
%%

% r1=[num2str(NPRCH),'     NPRCH'];
r2=[num2str(NRCHOP),' ',num2str(IRCHB),'     NRCHOP IRCHCB'];

% fprintf(fid,'%s \n',r1);
fprintf(fid,'%s \n',r2);


for i=1:NPER
    r3=[num2str(INRECH),'  INRECH '];
    r4=['INTERNAL 1.0 (FREE) 0 RECH Stress Period ',num2str(i) ];
    fprintf(fid,'%s \n',r3);
    fprintf(fid,'%s \n',r4);
    fmt=[repmat('%16.9f ',1,size(RECH(:,:,i),2)-1), '%16.9f\n'];
    fprintf(fid,fmt,RECH(:,:,i)'); %write X (IC's)
end
status=fclose(fid);
end
