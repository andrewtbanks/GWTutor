function [  ] = LPFwrite(struct)
% write LPF file
% consult MODFLOW 2005 documentation for description of file formatting. 
% data is written from input structure (struct) into LPF file 

%write filename.OC
%VARIBELS
filename=struct.NAM.filename;
LAYTYP=struct.LPF.LAYTYP; %0 is confined, <0 if unconfined 
LAYAVG=struct.LPF.LAYAVG; %0 is harmonic mean
CHANI=struct.LPF.CHANI; %horizontal anisotropy for whole layer 
LAYVKA=struct.LPF.LAYVKA; %flag for whether VKA is vertical hydraulic conductivity or ratio VK/HK
LAYWET=struct.LPF.LAYWET; %contains a flag for each layer that indicates if wetting is active
VKA=struct.LPF.VKA; %ratio of horizaontal to vertical hydraulic conductivity
HK=struct.LPF.HK; %horizontal hydraulic conductivity 
HANI=struct.LPF.HANI; %ratio of along col to along row K
VKA=struct.LPF.VKA;%vertical  hydraulic conductivity 
quasiVKA=struct.LPF.quasiVKA; %VKA for quasi 3d confinig layer
Ss=struct.LPF.Ss;%specific storage
Sy=struct.LPF.Sy; %specific yeild
NLAY=struct.DIS.NLAY;
HDRY=struct.BA6.HDRY;
LAYCBD=struct.DIS.LAYCBD;

%%
filepath=strjoin({pwd,filename,filename},'\');
fname = [filepath,'.LPF'];
fid=fopen(fname,'wt');

% r1='# Layer-Property Flow Package input'; 
% r2='# For transient simulation';
r3=['     11     ',num2str(HDRY), '    0                          ILPFCB, HDRY, NPLPF'];%, THICKSTRT';
r4=[' ',num2str(LAYTYP),'                                            LAYTYP '];
r5=[' ',num2str(LAYAVG),'                                            LAYAVG-- 0 = HARMONIC MEAN'];
r6=['  ',num2str(CHANI),'                                        CHANI'];
r7=[' ',num2str(LAYVKA),'                                            LAYVKA'];
r8=[' ',num2str(LAYWET),'                                           LAYWET'];
% fprintf(fid,'%s',r1); fprintf(fid,'\n');
% fprintf(fid,'%s',r2); fprintf(fid,'\n');
fprintf(fid,'%s',r3); fprintf(fid,'\n');
fprintf(fid,'%s',r4); fprintf(fid,'\n');
fprintf(fid,'%s',r5); fprintf(fid,'\n');
fprintf(fid,'%s',r6); fprintf(fid,'\n');
fprintf(fid,'%s',r7); fprintf(fid,'\n');
fprintf(fid,'%s',r8); fprintf(fid,'\n');
cnt=1;
for i=1:NLAY
    r9=['INTERNAL 1.0  (FREE)         '];
    fprintf(fid,'%s',r9); fprintf(fid,'\n');
    fmt=[repmat('%16.9f ',1,size(HK(:,:,i),2)-1), '%16.9f\n'];
    fprintf(fid,fmt,HK(:,:,i)'); 
    
    r10=['INTERNAL 1.0  (FREE)       '];
    fprintf(fid,'%s',r10); fprintf(fid,'\n');
    fmt=[repmat('%16.9f ',1,size(HANI(:,:,i),2)-1), '%16.9f\n'];
    fprintf(fid,fmt,HANI(:,:,i)') ;
    
    r11=['INTERNAL 1.0  (FREE)       '];
    fprintf(fid,'%s',r11); fprintf(fid,'\n');
    fmt=[repmat('%16.9f ',1,size(VKA(:,:,i),2)-1), '%16.9f\n'];
    fprintf(fid,fmt,VKA(:,:,cnt)') ;
    
    if LAYCBD(i)==1
            r12=['INTERNAL 1.0  (FREE)       '];
            fprintf(fid,'%s',r11); fprintf(fid,'\n');
            fmt=[repmat('%16.9f ',1,size(quasiVKA(:,:,i),2)-1), '%16.9f\n'];
            fprintf(fid,fmt,quasiVKA(:,:,i)') ;
            
    end

%     r13=['CONSTANT    ',num2str(Ss(i)),'                             Ss layer ',num2str(i)];   
%     fprintf(fid,'%s',r13); fprintf(fid,'\n');

    r13=['INTERNAL 1.0  (FREE)       '];
    fprintf(fid,'%s',r13); fprintf(fid,'\n');
    fmt=[repmat('%16.9f ',1,size(Ss(:,:,i),2)-1), '%16.9f\n'];
    fprintf(fid,fmt,Ss(:,:,cnt)') ;

    if LAYTYP(i) > 0
        
%             r14=['CONSTANT    ',num2str(Sy(i)),'                             Sy layer',num2str(i)];
%             fprintf(fid,'%s',r14); fprintf(fid,'\n');
            
            r14=['INTERNAL 1.0  (FREE)       '];
            fprintf(fid,'%s',r14); fprintf(fid,'\n');
            fmt=[repmat('%16.9f ',1,size(Sy(:,:,i),2)-1), '%16.9f\n'];
            fprintf(fid,fmt,Sy(:,:,cnt)') ;
    end
    
end


status=fclose(fid);

end