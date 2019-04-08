function [] = PCGwrite(struct)
% write pcg file - solver options
% consult MODFLOW 2005 documentation for description of file formatting. 
% data is written from input structure (struct) into PCG file 

filename=struct.NAM.filename;
MXITER=struct.PCG.MXITER;%maximum number of iterations to call for PCG solution routine
HCLOSE=struct.PCG.HCLOSE;%head change criterion for convergence in units of length (LENUNI)
RCLOSE=struct.PCG.RCLOSE;%residual criterion for conbvergence

%write filename.PCG

% r1=['       ',num2str(MXITER),'         8         1    MXITER,ITER1,NPCOND'];
r1=['       ',num2str(MXITER),'         8         1    ']; %changed bc text caused issues on some computers
r2=['  ',num2str(HCLOSE),'    ',num2str(RCLOSE),'        1.         2        1          0      1.00'];
r3=[' HCLOSE,      RCLOSE,    RELAX,    NBPOL,     IPRPCG,   MUTPCG    damp'];

filepath=strjoin({pwd,filename,filename},'\');
fname = [filepath,'.PCG'];
fid=fopen(fname,'wt');
fprintf(fid,'%s',r1); fprintf(fid,'\n');
fprintf(fid,'%s',r2); fprintf(fid,'\n');
fprintf(fid,'%s',r3); fprintf(fid,'\n');

status=fclose(fid);
end

