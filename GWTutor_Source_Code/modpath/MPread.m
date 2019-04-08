function [out] = MPread( MPstruct,type)
% read  particle trajcetories from MODPATH output

% type indicates what output is returned (always reads endpoint,reads timeseries if type = 'timeseries') 
filename=MPstruct.MPNAM.filename;
ntimepoints=length(MPstruct.MPSIM.TIMEPOINTS);
particlecount=MPstruct.SLOC.ParticleCount;
%read .endpoint file

disp('reading Modpath')
fname=[filename,'.endpoint'];
filepath=strjoin({pwd,filename,fname},'\');
%disp(filepath);

%pause if id file does not exist
IDpath=strsplit(pwd,'\');
IDpath(end+1)={filename};
IDpath(end+1)={strcat(filename,'_modpathID.txt')};
IDpath=strjoin(IDpath,'\');
IDexist = 0;
while IDexist == 0
   pause(1)  
    if exist(IDpath,'file') == 2
        IDexist = 1;
    end

end


fid=fopen(filepath);
temp.l1=textscan(fid,'%s %d %d',1);
temp.l2=textscan(fid,[repmat('%d ',[1,4]),'%f'],1);
temp.l3=textscan(fid,repmat('%d ',[1,10]),1);
temp.l4=textscan(fid,'%d',1);
temp.l5=textscan(fid,'%s',1);
temp.l6=textscan(fid,'%s %s',1);

out.TrackDir=cell2mat(temp.l2(1)); 
out.ReleaseCount=cell2mat(temp.l2(3));
out.ReferenceTime=cell2mat(temp.l2(5));
out.StatusCount=cell2mat(temp.l3);

for i=1:out.ReleaseCount
temp.record=textscan(fid,'%d %d %d %d %f %f %d %d %f %f %f %f %f %f %d %d %d %d %f %f %f %f %f %f %d %d ',1,'Delimiter','\t');
name=genvarname(strcat('particle',num2str(i)));
out.(name).SequenceNum=cell2mat(temp.record(1));
out.(name).ParticleGroup=cell2mat(temp.record(2));
out.(name).ParticleID=cell2mat(temp.record(3));
out.(name).Status=cell2mat(temp.record(4));
out.(name).InitialTrackingTime=cell2mat(temp.record(5));
out.(name).FinalTrackingTime=cell2mat(temp.record(6));
out.(name).InitialCellNumber=cell2mat(temp.record(7));
out.(name).InitialLayer=cell2mat(temp.record(8));
out.(name).InitialLocalXYZ=cell2mat(temp.record(9:11));
out.(name).InitialGlobalXYZ=cell2mat(temp.record(12:14));
out.(name).InitialZone=cell2mat(temp.record(15));
out.(name).InitialFace=cell2mat(temp.record(16));
out.(name).FinalCellNumber=cell2mat(temp.record(17));
out.(name).FinalLayer=cell2mat(temp.record(18));
out.(name).FinalLocalXYZ=cell2mat(temp.record(19:21));
out.(name).FinalGlobalXYZ=cell2mat(temp.record(22:24));
out.(name).FinalZone=cell2mat(temp.record(25));
out.(name).FinalFace=cell2mat(temp.record(26));
end
status=fclose(fid);


skip=1;
if skip==0 && strcmp(type,'pathline')==1;
% read pathline file
fname=[filename,'.pathline'];
filepath=strjoin({pwd,filename,fname},'\');
fid=fopen(filepath,'r');
% 
temp2.l1=textscan(fid,'%21c %d %d',1);
temp2.l2=textscan(fid,'%d %16.11f',1);
temp2.l3=textscan(fid,'%10c',1);
out.(name).pathline.ReferenceTime=cell2mat(temp2.l2(2));
% 
for i=1:out.ReleaseCount
 temp2a=textscan(fid,repmat('%d',[1,4]),1);
 name=genvarname(strcat('particle',num2str(i)));
 out.(name).pathline.SequenceNumber=cell2mat(temp2a(1));
 out.(name).pathline.Group=cell2mat(temp2a(2));
 out.(name).pathline.ParticleID=cell2mat(temp2a(3));
 out.(name).pathline.PathlinePointCount=cell2mat(temp2a(4));
    for j=1:out.(name).pathline.PathlinePointCount
    temp2=textscan(fid,['%d %16.9f %16.9f %16.9f %14c %16.9f %16.9f %16.9f\t\t%d\t\t%d\t\t%d\n'],1);
    out.(name).pathline.CellNumber(j)=cell2mat(temp2(1));
    out.(name).pathline.GlobalXYZ(:,j)=cell2mat(temp2(2:4));  
    out.(name).pathline.LocalXYZ(:,j)=cell2mat(temp2(6:8)); 
    out.(name).pathline.Layer(j)=cell2mat(temp2(9)); 
    out.(name).pathline.StressPeriod(j)=cell2mat(temp2(10)); 
    out.(name).pathline.TimeStep(j)=cell2mat(temp2(11)); 
    end
end
status=fclose(fid);
end

%% read timeseries file

if strcmp(type,'timeseries')==1
fname=[filename,'.timeseries'];
filepath=strjoin({pwd,filename,fname},'\');
fid=fopen(filepath);

temp3.l1=textscan(fid,'%s %d %d',1);
temp3.l2=textscan(fid,'%d %f',1);
temp3.l3=textscan(fid,'%s %s',1);
pcnt=ones(1,out.ReleaseCount);
for i=1:(ntimepoints+1)*(out.ReleaseCount)
    cnt=i;
        temp3a=textscan(fid,['%8d %8d %f %8d %8d %8d %8d ',repmat('%f ',[1,6]),'%8d '],1,'Delimiter','\t');
        pid=cell2mat(temp3a(6));
        name=genvarname(strcat('particle',num2str(pid)));
        out.(name).timeseries.TimePointIndex(pcnt(pid))=cell2mat(temp3a(1));
        out.(name).timeseries.CumulativeTimeStep(pcnt(pid))=cell2mat(temp3a(2));
        out.(name).timeseries.TrackingTime(pcnt(pid))=cell2mat(temp3a(3));
        out.(name).timeseries.SequenceNumber(pcnt(pid))=cell2mat(temp3a(4));
        out.(name).timeseries.ParticleGroup(pcnt(pid))=cell2mat(temp3a(5));
        out.(name).timeseries.ParticleID(pcnt(pid))=cell2mat(temp3a(6));
        out.(name).timeseries.CellNumber(pcnt(pid))=cell2mat(temp3a(7));
        out.(name).timeseries.LocalXYZ(:,pcnt(pid))=cell2mat(temp3a(8:10));
        out.(name).timeseries.GlobalXYZ(:,pcnt(pid))=cell2mat(temp3a(11:13));
        out.(name).timeseries.Layer(pcnt(pid))=cell2mat(temp3a(14));
        pcnt(pid)=pcnt(pid)+1;  
end 
status=fclose(fid);
end
disp('done reading Modpath')
end

