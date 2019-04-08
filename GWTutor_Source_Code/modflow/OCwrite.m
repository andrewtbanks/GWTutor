function [  ] = OCwrite(struct)
% write output control file
% consult MODFLOW 2005 documentation for description of file formatting. 
% data is written from input structure (struct) into OC file 
filename=struct.NAM.filename;
NPER=struct.DIS.NPER;
NSTP=struct.DIS.NSTP;

%write filename.OC
filepath=strjoin({pwd,filename,filename},'\');
fname = [filepath,'.OC'];
fid=fopen(fname,'wt');

r1='HEAD PRINT FORMAT   0';
r2='DRAWDOWN PRINT FORMAT   0';
r3='HEAD SAVE UNIT 15';
r4='COMPACT BUDGET AUXILIARY';

fprintf(fid,'%s',r1); fprintf(fid,'\n');
fprintf(fid,'%s',r2); fprintf(fid,'\n');
fprintf(fid,'%s',r3); fprintf(fid,'\n');
fprintf(fid,'%s',r4); fprintf(fid,'\n');


for i=1:NPER
    for j=1:NSTP
    r5=['PERIOD   ',num2str(i),' STEP   ',num2str(j)];
    r6='    PRINT BUDGET';
    r7='    SAVE BUDGET';
    r8='    PRINT HEAD';
    r9='	SAVE HEAD';
fprintf(fid,'%s',r5); fprintf(fid,'\n');
fprintf(fid,'%s',r6); fprintf(fid,'\n');
fprintf(fid,'%s',r7); fprintf(fid,'\n');
fprintf(fid,'%s',r8); fprintf(fid,'\n');
fprintf(fid,'%s',r9); fprintf(fid,'\n');
    end

end
% 
% r5=['PERIOD   ',num2str(RETURNPER),' STEP   ',num2str(RETURNSTEP)];
% r6='    PRINT BUDGET';
% r7='    SAVE BUDGET';
% r8='    PRINT HEAD';
% r9='	SAVE HEAD';
% fprintf(fid,'%s',r5); fprintf(fid,'\n');
% fprintf(fid,'%s',r6); fprintf(fid,'\n');
% fprintf(fid,'%s',r7); fprintf(fid,'\n');
% fprintf(fid,'%s',r8); fprintf(fid,'\n');
% fprintf(fid,'%s',r9); fprintf(fid,'\n');


status=fclose(fid);

end
