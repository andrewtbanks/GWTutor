function [ind,sub,loc] = GlobalXYZ2ind(GlobalXYZ,struct)
% converts global XYZ coordinate to cell index using knowledge of cell
% discretization contained in ModelStruct

% accept global XYZ coordinated for a  particle  and modpath discretization information

% returns ind = row,col,lay indicies 
% returns sub = [i,j,k] positions in the matrixies storing data  
% returns loc = [xloc,yloc,zloc] local x,y,z coordinated for each row-col-lay index within ind 


% get discretization info
ncol=struct.DIS.NCOL;
nrow=struct.DIS.NROW;
nlay=struct.DIS.NLAY;
top=struct.DIS.TOP;
bot=struct.DIS.BOT;
dr=struct.DIS.DELR;
dc=struct.DIS.DELC;

% global x-y-z position of particle 
X=GlobalXYZ(1);
Y=GlobalXYZ(2);
Z=GlobalXYZ(3);

% domain limits 
xdom=cumsum(dr); xdom(2:end+1)=xdom; xdom(1)=0;
ydom=cumsum(dc); ydom(2:end+1)=ydom; ydom(1)=0; ydom=fliplr(ydom);
ZDOM=zeros([size(bot,1) size(bot,2) size(bot,3)+1]);
ZDOM(:,:,1)=top;
ZDOM(:,:,2:end)=bot;

%% Check to see if current coordinate is exactly equal to XYZ coordinate
if isempty(find(xdom==X))==0; %condition met if Global X is exactly on a cell boundary. 
    xflag=1;
    xpos=find(xdom==X);
    locX=0;

if xpos==length(xdom)
       xpos=length(xdom)-1;
       xflag=2;
       locX=1;
   end
   
else
xflag=3;
xnear=find(xdom<X);
xpos=xnear(end);

locX=(X-xdom(xpos))/dr(xpos);

end
col=xpos;

if isempty(find(ydom==Y))==0; %condition met if Global X is exactly on a cell boundary. 
    yflag=1;
     ypos=find(ydom==Y)-1;
     locY=0;
         
     if ypos==length(ydom)
         yflag=2;
         ypos=length(ydom)-1;
         locY=1;
     elseif ypos==0
         yflag=3;
         ypos=1;
         locY=0; 
     end

else
     yflag=4;
     ynear=find(ydom>Y);
     ypos=ynear(end);
     ydom(ypos);
     
     locY=1-(ydom(ypos)-Y)/dc(ypos);
end
row=ypos;

zdom(1:size(ZDOM,3))=round(ZDOM(row,col,:),9);
if isempty(find(zdom==Z))==0; %condition met if Global Z is exactly on a cell boundary. 
    zflag=1;
    zpos=find(Z==zdom);
    locZ=0;
    if zpos==length(zdom)
        zflag=2;
        zpos=nlay;
        locZ=0;
    elseif zpos==1
        zflag=3;
        zpos=1;
        locZ=1;
    end
    
else 
    zflag=4;
    znear=find(zdom>Z);
    zpos=znear(end);
    locZ=((Z-zdom(zpos+1))/(zdom(zpos)-zdom(zpos+1)));   
end
zflag;
lay=zpos; 
sub=[col,row,lay];
loc=[locX,locY,locZ];
ind=sub2ind([ncol,nrow,nlay],col,row,lay);

end

