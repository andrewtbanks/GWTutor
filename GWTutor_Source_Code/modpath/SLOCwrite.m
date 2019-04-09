function [ ] = SLOCwrite( MPstruct )
% Author: Andy Banks 2019 - Univeristy of Kansas Dept of Geology 
% GWTutor MODFLOW/MODPATH support library 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Writes SLOC -Modpath starting locations file
% consult MODPATH 6  documentation for description of file formatting. 
% data is written from input structure (MPstruct) into SLOC file 

TimeOffset=MPstruct.SLOC.TimeOffset;
Drape=MPstruct.SLOC.Drape;

LocationStyle=MPstruct.SLOC.LocationStyle;
InitialLocalXYZ=MPstruct.SLOC.InitialLocalXYZ;

if LocationStyle==1
    InitialSub=MPstruct.SLOC.InitialSub; %[layer row column]
elseif LocationStyle==2
    InitialCellNumber=MPstruct.SLOC.InitialCellNumber;
end

ParticleCount=MPstruct.SLOC.ParticleCount;
ParticleIdOption=MPstruct.SLOC.ParticleIdOption;

if ParticleIdOption==1
    ParticleID=MPstruct.SLOC.ParticleID;
else 
    ParticleID=repmat('',1,ParticleCount);
end

%%
filename=MPstruct.MPNAM.filename;
filepath=strjoin({pwd,filename,filename},'\');
fname=[filepath,'.sloc'];
fid=fopen(fname,'wt');

r1=['1'];%input style 
r2=[num2str(LocationStyle)]; %location style
r3=[num2str(ParticleCount),'  ',num2str(ParticleIdOption)]; %particle count, particle option 
fprintf(fid,'%s',r1); fprintf(fid,'\n');
fprintf(fid,'%s',r2); fprintf(fid,'\n');
fprintf(fid,'%s',r3); fprintf(fid,'\n');

for i=1:ParticleCount
    if LocationStyle==1
        r4=[num2str(ParticleID(i)),' ',num2str(InitialSub(i,1)),' ',num2str(InitialSub(i,2)),' ',num2str(InitialSub(i,3)),' ',num2str(InitialLocalXYZ(i,1)),' ',num2str(InitialLocalXYZ(i,2)),' ',num2str(InitialLocalXYZ(i,3)),' ',num2str(TimeOffset(i)),' ', num2str(Drape(i))]; %particle position on cell    
    else      
        r4=[num2str(ParticleID(i)),'  ',num2str(InitialCellNumber(i)),' ',num2str(InitialLocalXYZ(i,1)),' ',num2str(InitialLocalXYZ(i,2)),' ',num2str(InitialLocalXYZ(i,3)),' ',num2str(TimeOffset(i)),' ', num2str(Drape(i))]; %particle position on cell
    end
    fprintf(fid,'%s',r4); fprintf(fid,'\n');
end
status=fclose(fid);

end

