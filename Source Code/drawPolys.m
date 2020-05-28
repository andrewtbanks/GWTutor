function [ dis ] = drawPolys(dis)
% Author: Andy Banks 2019 - Univeristy of Kansas Dept of Geology 
% GWTutor MODFLOW/MODPATH support library 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Used by GWTutor_INPUT_GUI.m and GWTutor_OUTPUT_GUI.m
% Draws a set of polygons describing the saturated thickness of the aquifer
% Uses base elevation of aquifer and current heads to draw a polygon for each cell 
% Returns dis structure contating polygon verticies for the 3-D grids in the GUI

% x verticies for top/bot cell faces
 for j = 1:dis.ncol 
    dis.PolyX(:,j) = [dis.xpos(j) dis.xpos(j) dis.xpos(j+1) dis.xpos(j+1)];
 end
 dis.PolyX = repmat(dis.PolyX,[1,dis.nrow]);
 
% y verticies for top/bottom cell faces
ycnt = 1;
for i = 1:dis.nrow
    dis.PolyY(:,[ycnt:ycnt+dis.ncol-1]) = repmat([dis.ypos(i) dis.ypos(i+1) dis.ypos(i+1) dis.ypos(i)]',[1,dis.ncol]);
    ycnt = ycnt+dis.ncol;
end

% z verticies for layers and params
for k = 1:dis.nlay+1
    currElev = reshape(dis.ELEV(:,:,k)',1,[]); % get elevation of cells in current layer
    if k == 1 
     currElevSat = reshape(dis.ELEVsat(:,:,k)',1,[]);  
     dis.PolyZ(1,:,k) = currElevSat;
     dis.PolyZ(2,:,k) = currElevSat;
     dis.PolyZ(3,:,k) = currElevSat;
     dis.PolyZ(4,:,k) = currElevSat;
    else
     dis.PolyZ(1,:,k) = currElev;
     dis.PolyZ(2,:,k) = currElev;
     dis.PolyZ(3,:,k) = currElev;
     dis.PolyZ(4,:,k) = currElev;
    end
    

    % upade polygons for all other 3-D fields 
    if k<=dis.nlay
    currElevBot = reshape(dis.ELEV(:,:,k+1)',1,[]);
    
    % reshape each parameter field toa 1xn vector 
    currIbound = reshape(dis.ibound(:,:,k)',1,[]);
    currIboundEdge = currIbound;
    currIboundEdge(currIbound ~=1)=0;

    currRCH = reshape(dis.RCHbase(:,:,k)',1,[]);    
    currKr = reshape(dis.KRbase(:,:,k)',1,[]);
    currKc = reshape(dis.KCbase(:,:,k)',1,[]);
    currKv = reshape(dis.KVbase(:,:,k)',1,[]);
    currKhet1 = reshape(dis.KHET1(:,:,k)',1,[]);
    currKhet2 = reshape(dis.KHET2(:,:,k)',1,[]);
    currKhet12 = reshape(dis.KHET12(:,:,k)',1,[]);    
    currH = reshape(dis.H(:,:,k)',1,[]);
    currQ = reshape(dis.QREF(:,:,k)',1,[]);
    currSS = reshape(dis.SSbase(:,:,k)',1,[]);
    currSY = reshape(dis.SYbase(:,:,k)',1,[]);
    currP = reshape(dis.PorosityBase(:,:,k)',1,[]);
    
    % polygons for boundary condtions 
    dis.PolyZibound(1,:,k) = currIbound;
    dis.PolyZibound(2,:,k) = currIbound;
    dis.PolyZibound(3,:,k) = currIbound;
    dis.PolyZibound(4,:,k) = currIbound;
    
    dis.PolyZiboundEdge(1,:,k) = currIboundEdge;
    dis.PolyZiboundEdge(2,:,k) = currIboundEdge;
    dis.PolyZiboundEdge(3,:,k) = currIboundEdge;
    dis.PolyZiboundEdge(4,:,k) = currIboundEdge;
    
    % ploygons for reacharge 
    dis.PolyZrch(1,:,k) = currRCH;
    dis.PolyZrch(2,:,k) = currRCH;
    dis.PolyZrch(3,:,k) = currRCH;
    dis.PolyZrch(4,:,k) = currRCH;
    
    % polygons for hydraulic conductivity along rows
    dis.PolyZkr(1,:,k) = currKr;
    dis.PolyZkr(2,:,k) = currKr;
    dis.PolyZkr(3,:,k) = currKr;
    dis.PolyZkr(4,:,k) = currKr;
    % polygons for hydraulic conductivity along cols
    dis.PolyZkc(1,:,k) = currKc;
    dis.PolyZkc(2,:,k) = currKc;
    dis.PolyZkc(3,:,k) = currKc;
    dis.PolyZkc(4,:,k) = currKc;
    % polygons for hydraulic conductivity along layers
    dis.PolyZkv(1,:,k) = currKv;
    dis.PolyZkv(2,:,k) = currKv;
    dis.PolyZkv(3,:,k) = currKv;
    dis.PolyZkv(4,:,k) = currKv;
    
    % polygons for heterogenous hydraulic conductivitys
    dis.PolyZkhet1(1,:,k) = currKhet1;
    dis.PolyZkhet1(2,:,k) = currKhet1;
    dis.PolyZkhet1(3,:,k) = currKhet1;
    dis.PolyZkhet1(4,:,k) = currKhet1;

    dis.PolyZkhet2(1,:,k) = currKhet2;
    dis.PolyZkhet2(2,:,k) = currKhet2;
    dis.PolyZkhet2(3,:,k) = currKhet2;
    dis.PolyZkhet2(4,:,k) = currKhet2;
    
    dis.PolyZkhet12(1,:,k) = currKhet12;
    dis.PolyZkhet12(2,:,k) = currKhet12;
    dis.PolyZkhet12(3,:,k) = currKhet12;
    dis.PolyZkhet12(4,:,k) = currKhet12;
    
    % polygons for bottom of potentiometric surface
    dis.PolyZH(1,:,k) = currElevBot+currH;
    dis.PolyZH(2,:,k) = currElevBot+currH;
    dis.PolyZH(3,:,k) = currElevBot+currH;
    dis.PolyZH(4,:,k) = currElevBot+currH;
    
    % ploygons for top of potentiometric surface
    dis.PolyZHcolor(1,:,k) = currH;
    dis.PolyZHcolor(2,:,k) = currH;
    dis.PolyZHcolor(3,:,k) = currH;
    dis.PolyZHcolor(4,:,k) = currH;
    
    % polygons for pumping rates
    dis.PolyZQ(1,:,k) = currQ;
    dis.PolyZQ(2,:,k) = currQ;
    dis.PolyZQ(3,:,k) = currQ;
    dis.PolyZQ(4,:,k) = currQ;
    
    % polygons for storage terms
    dis.PolyZSS(1,:,k) = currSS;
    dis.PolyZSS(2,:,k) = currSS;
    dis.PolyZSS(3,:,k) = currSS;
    dis.PolyZSS(4,:,k) = currSS;
    
    dis.PolyZSY(1,:,k) = currSY;
    dis.PolyZSY(2,:,k) = currSY;
    dis.PolyZSY(3,:,k) = currSY;
    dis.PolyZSY(4,:,k) = currSY;

    % polygons for potosity
    dis.PolyZP(1,:,k) = currP;
    dis.PolyZP(2,:,k) = currP;
    dis.PolyZP(3,:,k) = currP;
    dis.PolyZP(4,:,k) = currP;
     
    end
    
end


%% make  polygons to reperesnt potentiometric surface and top elevation of the aquifer (thtese 
% x verticies for sides
 for j = 1:dis.ncol
     dis.PolyXsideL(:,j) = [dis.xpos(j) dis.xpos(j) dis.xpos(j) dis.xpos(j)];
     dis.PolyXsideR(:,j) = [dis.xpos(j+1) dis.xpos(j+1) dis.xpos(j+1) dis.xpos(j+1)];
     dis.PolyXsideFB(:,j) = [dis.xpos(j) dis.xpos(j) dis.xpos(j+1) dis.xpos(j+1)];
 end
 dis.PolyXsideL = repmat(dis.PolyXsideL,[1,dis.nrow]);
 dis.PolyXsideR = repmat(dis.PolyXsideR,[1,dis.nrow]);
 dis.PolyXsideFB = repmat(dis.PolyXsideFB,[1,dis.nrow]);
 
%  y verticies for sides
ycnt = 1;
for i = 1:dis.nrow
     dis.PolyYsideLR(:,[ycnt:ycnt+dis.ncol-1]) = repmat([dis.ypos(i) dis.ypos(i) dis.ypos(i+1) dis.ypos(i+1)]',[1,dis.ncol]);
     dis.PolyYsideF(:,[ycnt:ycnt+dis.ncol-1]) = repmat([dis.ypos(i) dis.ypos(i) dis.ypos(i) dis.ypos(i)]',[1,dis.ncol]);
     dis.PolyYsideB(:,[ycnt:ycnt+dis.ncol-1]) = repmat([dis.ypos(i+1) dis.ypos(i+1) dis.ypos(i+1) dis.ypos(i+1)]',[1,dis.ncol]);
    ycnt = ycnt+dis.ncol;
end

%z verticies for sides
for k = 1:dis.nlay
    currElevTop = reshape(dis.ELEV(:,:,k)',1,[]);
    currElevBot = reshape(dis.ELEV(:,:,k+1)',1,[]);
    currElevSat = reshape(dis.ELEVsat(:,:,k)',1,[]);
    
    dis.PolyZside(1,:,k) = currElevSat;
    dis.PolyZside(2,:,k) = currElevBot;
    dis.PolyZside(3,:,k) = currElevBot;
    dis.PolyZside(4,:,k) = currElevSat;
    
    
    %for head dependent polygon height     
    currH = reshape(dis.H(:,:,k)',1,[]);
    dis.PolyZsideH(1,:,k) = currElevBot+currH;
    dis.PolyZsideH(2,:,k) = currElevBot;
    dis.PolyZsideH(3,:,k) = currElevBot;
    dis.PolyZsideH(4,:,k) = currElevBot+currH;

end
            
currElev = reshape(dis.ELEV(:,:,1)',1,[]);
dis.PolyZtop = dis.PolyZ(:,:,1); % for the plane of true thickness 
dis.PolyZtop(1,:,1) = currElev;
dis.PolyZtop(2,:,1) = currElev;
dis.PolyZtop(3,:,1) = currElev;
dis.PolyZtop(4,:,1) = currElev;





end

