function [ MFfig ] = CE_demo_MF( dis,plt,MFin,MPin)
%dum = []; % dummy variable 

%%  Run modflow 
% build waitbar 
wb = waitbar(0,'Format and Write MODFLOW 2005 Input Files','Position',[800 700 300 50]); 
MFout = Format_ModFlow(MFin);% format data for modflow input files

% delete gui_ex1 directory if it exists
modelDirectory = strcat(pwd,filesep,'gui_ex1')
check = 7==exist(modelDirectory,'dir')

if check == 1
   rmdir(modelDirectory, 's')
end

MFwrite(MFout); %write modflow input files
waitbar(5/100,wb,'Run MODFLOW 2005');
MFrun(MFout); % run modflow 
[~,H,BUDGET]=MFread(MFout);
while exist('H') ~= 1
    pause(1);
end
%%  get head for each period - for the main tab of the output window 
Hraw = zeros([numel(MFin.H0),MFin.nper+1]);
SatThick = zeros(size(Hraw));
SatThick(:,1) = dis.PolyZtop(1,:);
 for i=1:MFin.nper+1
         if i==1
          Hplot(:,:,i) = MFin.H0';
          Hraw(:,i) = reshape(MFin.H0,1,[]);
         else     
          Hplot(:,:,i) = reshape(H(:,1,MFin.nsteps(1),i-1),MFin.ncol,MFin.nrow);
          Hraw(:,i) = reshape(reshape(H(:,1,MFin.nsteps(1),i-1),MFin.ncol,MFin.nrow),1,[]);
         end
         if i>1
             
             for k = 1:numel(Hraw(:,i))
                 
                if Hraw(k,i)< 1.05*SatThick(k,i-1)   % if H<elev at cell set equal to sat thickness (Hraw)
                  SatThick(k,i) = Hraw(k,i) ;
                else
                  SatThick(k,i) = SatThick(k,1);
                end
         end

         end
 end
Hmax = max((max(max(max(MFin.H0)))),ceil(max(max(max(max(H))))));
Hmin = ceil(min(min(min(min(H)))));
% force initial sat thickness to be correct 
if MFin.laytyp == 1
SatThick(:,1) = dis.PolyZH(1,:);
end

%% Run Modpath 
% update waitbar
waitbar(40/100,wb,'Format and Write MODPATH 7 Input Files')
MPout = Format_Modpath(MPin); % format data for modpath input files
MPwrite(MFout,MPout); % write modpath input files
waitbar(55/100,wb,'Running MODPATH 7')
MPrun(MPout);% run modpath 
mpath = MPread(MPout,'timeseries');% read modpath data
waitbar(95/100,wb,'New Window Will Open Shortly')
close(wb) % close waitbar window 


%% retrieve particle trajectories and identify stopping regions
MP.Paths = [];
save('tempMF','mpath');
stopcnt = 0;
stopCntInd = []; 
status = [];
for i = 1:MPin.ParticleCount
    name = genvarname(strcat('particle',num2str(i)));
    temp = mpath.(name).timeseries.GlobalXYZ;
    status(i) = mpath.(name).Status;
    stopZoneInd(i) = mpath.(name).FinalZone;
    temp2 = [];
    
    % retrieve path up to termination point for each particle - if
    % terminated early, copy last position to fill remainder of array
    if size(temp,2) < length(MPin.timepoints) && size(temp,2) > 2 ;
        stopCntInd(i) = size(temp,2);
        temp2(:,1:size(temp,2)) = temp;
        temp2(:,size(temp,2)+1:length(MPin.timepoints)) = repmat(temp(:,end),[1,length(MPin.timepoints)-length(temp)]);        
        
    elseif size(temp,2) == 2
        stopCntInd(i) = size(temp,2);
        temp2(:,1:size(temp,2)) = temp;
        temp2(:,size(temp,2)+1:length(MPin.timepoints)) = repmat(temp(:,end),[1,length(MPin.timepoints)-length(temp)+1]);        
    elseif size(temp,2) == 1
        stopCntInd(i) = size(temp,2);
        temp2 = repmat(temp,[1,length(MPin.timepoints)]);        
    else
        stopCntInd(i) = length(MPin.timepoints);
        temp2 = temp;
    end
    
    temp2(:,end+1) = mpath.(name).FinalGlobalXYZ;
    MP.Paths(:,:,i) = temp2;    
end


% for every timestep, determine which zone each particle is in  
dis.xposCent(dis.Qcol) 
dis.yposCent(dis.Qrow) 
            
MP.PathsA = MP.Paths(:,:,1:MPin.ParticleCountA);
MP.PathsB = MP.Paths(:,:,size(MP.PathsA,3)+1:size(MP.PathsA,3)+MPin.ParticleCountB);
MP.PathsC = MP.Paths(:,:,2*size(MP.PathsA,3)+1:2*size(MP.PathsA,3)+MPin.ParticleCountC);

statusA = status(1:MPin.ParticleCountA);
statusB = status(size(MP.PathsA,3)+1:size(MP.PathsA,3)+MPin.ParticleCountB);
statusC = status(2*size(MP.PathsA,3)+1:2*size(MP.PathsA,3)+MPin.ParticleCountC);

stopCntIndA = stopCntInd(1:MPin.ParticleCountA);
stopCntIndB = stopCntInd(size(MP.PathsA,3)+1:size(MP.PathsA,3)+MPin.ParticleCountB);
stopCntIndC = stopCntInd(2*size(MP.PathsA,3)+1:2*size(MP.PathsA,3)+MPin.ParticleCountC);

stopZoneIndA = stopZoneInd(1:MPin.ParticleCountA);
stopZoneIndB = stopZoneInd(size(MP.PathsA,3)+1:size(MP.PathsA,3)+MPin.ParticleCountB);
stopZoneIndC = stopZoneInd(2*size(MP.PathsA,3)+1:2*size(MP.PathsA,3)+MPin.ParticleCountC);

wellTermAind = find(stopZoneIndA == 3);
if isempty(wellTermAind) == 0
    for i = wellTermAind
    MP.PathsA(1:2,stopCntIndA(i):end,i) = repmat([dis.xposCent(dis.Qcol),dis.yposCent(dis.Qrow+1)]',1,size(MP.PathsA(:,stopCntIndA(i):end,i),2));
    end
end
wellTermBind = find(stopZoneIndB == 3);
if isempty(wellTermBind) == 0
    for i = wellTermBind
    MP.PathsB(1:2,stopCntIndB(i):end,i) = repmat([dis.xposCent(dis.Qcol),dis.yposCent(dis.Qrow+1)]',1,size(MP.PathsB(:,stopCntIndB(i):end,i),2));
    end
end
wellTermCind = find(stopZoneIndC == 3);
if isempty(wellTermCind) == 0
    for i = wellTermCind
    MP.PathsC(1:2,stopCntIndC(i):end,i) = repmat([dis.xposCent(dis.Qcol),dis.yposCent(dis.Qrow+1)]',1,size(MP.PathsC(:,stopCntIndC(i):end,i),2));
    end
end

particleAind = 1:MPin.ParticleCountA;
particleBind = MPin.ParticleCountA+1:MPin.ParticleCountA+MPin.ParticleCountB;
particleCind = MPin.ParticleCountA+MPin.ParticleCountB +1:MPin.ParticleCount;


%% Make figure and tabs

MFfig = figure('Visible','off','Position',[600  0 800 800],'Name','Interactive Groundwater Module -- Output','NumberTitle','off');

AxVisible = 'on';
AxUnits = 'normalized';
AxPosition = [0.22 0.17  .6 .6];
AxColor = 'none';
AxYdir = 'reverse';
AxXAxisLocation = 'top';
AxTickDir = 'out';
AxPlotBoxAspectRatio = [dis.LxNrm dis.LyNrm .3];
AxFontSize = 8;
AxLabelFontSizeMultiplier = 1.5; 
AxTitleFontSizeMultiplier = 2;
% bgImg = imread('background.jpg');
tgroupInit = uitabgroup('Parent',MFfig);


% modflow results tab
MFTab = uitab('Parent', tgroupInit, 'Title', 'Hydraulic Head');
% backgroundax = axes('units','normalized','position',[0 0 1 1],'Parent',MFTab);
% uistack(backgroundax,'bottom'); imagesc(bgImg); set(backgroundax,'handlevisibility','off','visible','off');
MFax = axes('Visible',AxVisible,'Units',AxUnits,'position',AxPosition,'Color',AxColor,'YDir',AxYdir,'XAxisLocation',AxXAxisLocation,'TickDir',AxTickDir,'PlotBoxAspectRatio',AxPlotBoxAspectRatio,'FontSize',AxFontSize,'LabelFontSizeMultiplier',AxLabelFontSizeMultiplier,'TitleFontSizeMultiplier',AxTitleFontSizeMultiplier); 
MFax.Parent = MFTab;
set(gca,'color','none') 
camerapos = [15034/11       56744/15       25167/19  ];
set(MFax,'XLim',[0 dis.Lx]); set(MFax,'YLim',[0 dis.Ly],'CameraPosition',camerapos); 
set(MFax,'XTick',dis.xpos(dis.xposInd)); set(MFax,'YTick',dis.ypos(dis.yposInd)); 
set(MFax,'XTickLabel',dis.xpos(dis.xposInd)); set(MFax,'YTickLabel',dis.ypos(dis.yposInd)); 
xlabel(MFax,'X_d_i_s_t  (m)'); ylabel(MFax,'Y_d_i_s_t  (m)'); zlabel(MFax,'Z_d_i_s_t (m)');

initPscale = 1;

set(MFax,'ZLim',get(dis.initialax,'ZLim'),'ZTick',get(dis.initialax,'ZTick'),'ZTickLabel',get(dis.initialax,'ZTickLabel'),'PlotBoxAspectRatio',[dis.LxNrm dis.LyNrm 0.6]);
zlabel(MFax,'Z_d_i_s_t (m)');

% modpath results tab
MPTab = uitab('Parent', tgroupInit, 'Title', 'Particle Tracking');
MPax = axes('Visible',AxVisible,'Units',AxUnits,'position',AxPosition,'Color',AxColor,'YDir',AxYdir,'XAxisLocation',AxXAxisLocation,'TickDir',AxTickDir,'PlotBoxAspectRatio',AxPlotBoxAspectRatio,'FontSize',AxFontSize,'LabelFontSizeMultiplier',AxLabelFontSizeMultiplier);
set(gca,'color','none') 
MPax.Parent = MPTab;
camerapos = [15034/11       56744/15       25167/19  ];
set(MPax,'XLim',[0 dis.Lx]); set(MPax,'YLim',[0 dis.Ly]); set(MPax,'ZLim',[0 dis.LzTop],'CameraPosition',camerapos);
set(MPax,'XTick',dis.xpos(dis.xposInd)); set(MPax,'YTick',dis.ypos(dis.yposInd)); set(MPax,'ZTick',[dis.LzBot ,dis.LzTop]);
set(MPax,'XTickLabel',dis.xpos(dis.xposInd)); set(MPax,'YTickLabel',dis.ypos(dis.yposInd)); set(MPax,'ZTickLabel',{'Bottom layer 1','Top Layer 1'});
xlabel(MPax,'X_d_i_s_t  (m)'); ylabel(MPax,'Y_d_i_s_t  (m)'); zlabel(MPax,'Z_d_i_s_t (m)');
set(MPax,'ZLim',get(dis.initialax,'ZLim'),'ZTick',get(dis.initialax,'ZTick'),'ZTickLabel',get(dis.initialax,'ZTickLabel'),'PlotBoxAspectRatio',[dis.LxNrm dis.LyNrm 0.6]);
     
%%
%z verticies for sides
% get polygons for potentiometric surface
for k = 1:dis.nlay
    
    currElevTop = reshape(dis.ELEV(:,:,k)',1,[]);
    currElevBot = reshape(dis.ELEV(:,:,k+1)',1,[]);
    
    currK = log10(reshape(dis.KR(:,:,k)',1,[]));
    
    disH.PolyZside(1,:,k) = currElevTop;
    disH.PolyZside(2,:,k) = currElevBot;
    disH.PolyZside(3,:,k) = currElevBot;
    disH.PolyZside(4,:,k) = currElevTop;
    
    disH.PolyZK(1,:,k) = currK;
    disH.PolyZK(2,:,k) = currK;
    disH.PolyZK(3,:,k) = currK;
    disH.PolyZK(4,:,k) = currK;
    %for head dependent polygon height   
         for n = 1:MFin.nper+1 
            hcurr = Hplot(:,:,n);
            currH = reshape(hcurr,1,[]);
            
            hcurrBig = resizem(hcurr',[length(dis.ypos), length(dis.xpos)],'bilinear');
            disH.currHBig(:,n) = reshape(hcurrBig,[],1);
            dis.hcurrBig(:,:,n) = hcurrBig;
            
            
            disH.PolyZsideH(1,:,k,n) = currH;
            disH.PolyZsideH(2,:,k,n) = 0;
            disH.PolyZsideH(3,:,k,n) = 0;
            disH.PolyZsideH(4,:,k,n) = currH;
            
            disH.PolyZH(1,:,k,n) = currH;
            disH.PolyZH(2,:,k,n) = currH;
            disH.PolyZH(3,:,k,n) = currH;
            disH.PolyZH(4,:,k,n) = currH;  
            
            disH.PolyZsideHsat(1,:,k,n) = currElevBot + currH;
            disH.PolyZsideHsat(2,:,k,n) = currElevBot;
            disH.PolyZsideHsat(3,:,k,n) = currElevBot;
            disH.PolyZsideHsat(4,:,k,n) = currElevBot + currH;
            
            disH.PolyZHsat(1,:,k,n) = currElevBot + currH;
            disH.PolyZHsat(2,:,k,n) = currElevBot + currH;
            disH.PolyZHsat(3,:,k,n) = currElevBot + currH;
            disH.PolyZHsat(4,:,k,n) = currElevBot + currH;
           end
       
end %end k loop

%%plot head for initial step 
figure(MFfig);

n=1;

patch(dis.PolyXsideL,dis.PolyYsideLR,initPscale*dis.PolyZside,[1 1 1],'FaceAlpha',0.7,'EdgeAlpha',0.1,'Visible','on','Parent',MFax);
hold(MFax,'on')
patch(dis.PolyXsideR,dis.PolyYsideLR,initPscale*dis.PolyZside,[1 1 1],'FaceAlpha',0.7,'EdgeAlpha',0.1,'Visible','on','Parent',MFax);  
patch(dis.PolyXsideFB,dis.PolyYsideF,initPscale*dis.PolyZside,[1 1 1],'FaceAlpha',0.7,'EdgeAlpha',0.1,'Visible','on','Parent',MFax);
patch(dis.PolyXsideFB,dis.PolyYsideB,initPscale*dis.PolyZside,[1 1 1],'FaceAlpha',0.7,'EdgeAlpha',0.1,'Visible','on','Parent',MFax);  
patch(dis.PolyX,dis.PolyY,initPscale*dis.PolyZtop(:,:,1),[1 1 1],'FaceAlpha',0.2,'EdgeAlpha',0.1,'Visible','on','Parent',MFax);
patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),[1 1 1],'FaceAlpha',1,'EdgeAlpha',0.1,'Visible','on','Parent',MFax);

% patch(dis.PolyX,dis.PolyY,initPscale*dis.PolyZtop(:,:,1),[1 1 1],'FaceAlpha',0.2,'EdgeAlpha',0.1,'Visible','on','Parent',MFax);
surf(MFax,dis.X(:,:,1),dis.Y(:,:,1),dis.hcurrBig(:,:,1),'EdgeAlpha',0.2);

% colorbar 
pltH.Cbar = colorbar(MFax,'Visible','on','Position',[.19 .1 .45 .035 ],'Location','SouthOutside','FontSize',10); 
pltH.Cbar.Visible='on';
pltH.Cbar.Label.String='Hydraulic Head  [m]';
colormap(MFax,'parula');
caxis(MFax,[Hmin,Hmax]);

pltHP.Cbar = colorbar(MPax,'Visible','on','Position',[.25 .08 .3 .015 ],'Location','SouthOutside','FontSize',10); 
pltHP.Cbar.Visible='on';
pltHP.Cbar.Label.String='Hydraulic Head [m]';
colormap(MPax,'parula');
caxis(MPax,[Hmin,Hmax]);

pltHP.KCbar = colorbar(MPax,'Visible','off','Position',[.25 .08 .3 .015],'Location','SouthOutside','FontSize',10); 
pltHP.KCbar.Label.String='Hydraulic Conductivity [m/day]';
pltHP.KCbar.YTick = log10(dis.Krng);
pltHP.KCbar.YTickLabel = {'10^-^5','10^-^4','10^-^3','10^-^2','10^-^1','1^ ','10^ ','10^2','10^3','10^4'};



%% Plot domain and initial step for particles 
p1 = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),[1 1 1],'FaceAlpha',.2,'EdgeAlpha',0.1,'Visible','on','Parent',MPax);
hold(MPax,'on')
p2 = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),[1 1 1],'FaceAlpha',1,'EdgeAlpha',0.1,'Visible','on','Parent',MPax);
ParticlePosA = scatter3('Parent',MPax,dis.xunitA,dis.Ly-dis.yunitA,dis.zunitA,10,dis.PcolorA,'filled','Visible','on');
ParticlePosB = scatter3('Parent',MPax,dis.xunitB,dis.Ly-dis.yunitB,dis.zunitB,10,dis.PcolorB,'filled','Visible','on');
ParticlePosC = scatter3('Parent',MPax,dis.xunitC,dis.Ly-dis.yunitC,dis.zunitC,10,dis.PcolorC,'filled','Visible','on');

%plot hydraulic head as initial underlay 
patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),[1 1 1],'FaceAlpha',.2,'EdgeAlpha',0.1,'Visible','on','Parent',MPax);
hold(MPax,'on')
patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),disH.PolyZH(:,:,1,1),'FaceAlpha',1,'EdgeAlpha',0.1,'Visible','on');

MFtime_slider = uicontrol('style','slider','Position',[200 700 100 20],'Units','normalized','Min',0,'Max',MFin.nper,'Value',0,'SliderStep',[1/(MFin.nper+1) 1/(MFin.nper+1)],'Visible','on','Callback',@MFtime_slider_Callback,'Parent',MFTab);
MFtime_slider_txt = annotation(MFTab,'textbox','Position',[.24 .84 .100 .10],'String',['Time Elapsed: \bf \it', num2str(0),' Days'],'Visible','on','EdgeColor','none');

MF_TrSs_txt = annotation(MFTab,'textbox','Position',[.2 .7 .100 .10],'String',[' Stress Period Type   \bf \it {Initial Conditions} '],'Visible','on','EdgeColor','none','FontSize',12);
disp('laytype below')
disp(num2str(dis.laytyp))
if dis.laytyp ==1
confined_txt = annotation(MFTab,'textbox','Position',[.2 .75 .100 .10],'Units','normalized','String',[' Aquifer is \bf \it {Unconfined}'],'Visible','on','EdgeColor','none','FontSize',12);
else
confined_txt = annotation(MFTab,'textbox','Position',[.2 .75 .100 .10],'Units','normalized','String',[' Aquifer is \bf \it {Confined}'],'Visible','on','EdgeColor','none','FontSize',12);
end
MPtime_slider = uicontrol('style','slider','Position',[180 700 100 20],'Units','normalized','Min',0,'Max',MFin.nper,'Value',0,'SliderStep',[1/(MFin.nper+1) 1/(MFin.nper+1)],'Visible','on','Callback',@MPtime_slider_Callback,'Parent',MPTab);
MPtime_slider_txt = annotation(MPTab,'textbox','Position',[.215 .84 .100 .10],'String',['Time Elapsed: \bf \it ', num2str(0),' Days'],'Visible','on','EdgeColor','none');

% IC_text_str = {'Note: This is only an initial guess at the solution at the first timestep'; 'This hydraulic head distribution is not physically plausible '};
% IC_text = annotation(MFTab,'textbox','Position',[.65 .75 .3 .2],'String',IC_text_str,'Visible','off','FontSize',12);

particle_data = {0,0,0,MPin.ParticleCountA;0,0,0,MPin.ParticleCountB;0,0,0,MPin.ParticleCountC;0,0,0,MPin.ParticleCount};
Particle_data_table = uitable('Position' , [380 630 379.7421385 108.8021385],'Units','Normalized','Parent',MPTab);
Particle_data_table.Data = particle_data;
Particle_data_table.ColumnName = {'<html><font size=-2> Active','<html><font size=-2> Terminated<html><br/>   at Well','<html><font size=-2> Terminated<html><br/>   at Boundary','<html><font size=-2>Total'};
Particle_data_table.RowName = {'Group A','Group B','Group C','Total'};
Particle_data_table.BackgroundColor = [dis.PcolorA;dis.PcolorB;dis.PcolorC;[.9 .9 .9]];

pathline_check = uicontrol('style','checkbox','Position',[650 515 14 14],'Units','normalized','Value',0,'Callback',@MPtime_slider_Callback,'Parent',MPTab,'Visible','on');
pathline_check_txt = annotation(MPTab,'textbox','Position',[.84 .57 .100 .10],'Units','normalized','String',['Show pathlines'],'Visible','on','EdgeColor','none','FontSize',9);
hide_stop_well_check = uicontrol('style','checkbox','Position',[650 490 14 14],'Units','normalized','Value',0,'Callback',@MPtime_slider_Callback,'Parent',MPTab,'Visible','on');
hide_stop_well_txt = annotation(MPTab,'textbox','Position',[.84 .54 .100 .10],'Units','normalized','String',{'Hide particles when' ;' terminated'},'Visible','on','EdgeColor','none','FontSize',9);
well_check = uicontrol('style','checkbox','Position',[650 455 14 14],'Units','normalized','Value',0,'Callback',@MPtime_slider_Callback,'Parent',MPTab,'Visible','on');
well_txt = annotation(MPTab,'textbox','Position',[.84 .492 .100 .10],'Units','normalized','String',{'Show well'},'Visible','on','EdgeColor','none','FontSize',9);



overlay_popup = uicontrol('Style','popup','Position',[160 620 150 50],'Units','normalized','String',{['Hydraulic Head (H)'];['Hydraulic Conductivity']},'Value',1,'Visible','on','Callback',@MPoverlay_Callback,'ForegroundColor','black','Parent',MPTab);

function MPoverlay_Callback(source,events)
       n = ceil(MPtime_slider.Value);
        
        MPtime_slider_txt.String = ['Time Elapsed: \bf \it  ', num2str(n*dis.perlen),' Days'];
        
        n = n+1;
        
        cla(MPax);
        axes(MPax);
        hold(MPax,'on');
        
        FaceAlpha = 1;
        EdgeAlpha = 0.1;
        
        pltHP.Cbar.Visible = 'off';
        pltHP.KCbar.Visible = 'off';
        
        switch overlay_popup.Value
            case 1
            colormap(MPax,'parula');
            caxis(MPax,[Hmin,Hmax]);
            patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),disH.PolyZH(:,:,1,n),'FaceAlpha',FaceAlpha,'EdgeAlpha',EdgeAlpha,'Visible','on','Parent',MPax); 
            pltHP.Cbar.Visible = 'on';

            case 2
            
            caxis(MPax,dis.Klim);   
            colormap(MPax,summer(dis.nKvals));
            patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),disH.PolyZK,'FaceAlpha',FaceAlpha,'EdgeAlpha',EdgeAlpha,'Visible','on','Parent',MPax);
            pltHP.KCbar.Visible = 'on';

            
        end
        MPtime_slider_Callback

end
function MFtime_slider_Callback(source,events)

         cla(MFax)
        axes(MFax)
        n = ceil(MFtime_slider.Value);
        
        MFtime_slider_txt.String = ['Time Elapsed \bf \it: ', num2str(n*dis.perlen),' Days'];
        IC_text.Visible = 'off';
        
        
        if n == 0
            MF_TrSs_txt.String = [' Stress Period Type \bf \it { Initial Conditions }'];
            IC_text.Visible = 'on';
            
        elseif n == 1
            MF_TrSs_txt.String = [' Stress Period Type \bf \it { Steady State} '];
        else
            MF_TrSs_txt.String = [' Stress Period Type \bf \it { Transient} '];
        end
        

      
        %adjust n for adding H0 to Hplot 
        n=n+1;
        surf(MFax,dis.X(:,:,1),dis.Y(:,:,1),dis.hcurrBig(:,:,n),'Edgealpha',0.1);


        % use Sat thickness for new layers 
        % plot base model     
        MFin.laytyp
        if MFin.laytyp == 0 %if confined
            
            for k = 1:dis.nlay
                currElevTop = reshape(dis.ELEV(:,:,k)',1,[]);
                currElevBot = reshape(dis.ELEV(:,:,k+1)',1,[]);

                dis.PolyZside(1,:,k) = currElevTop;
                dis.PolyZside(2,:,k) = currElevBot;
                dis.PolyZside(3,:,k) = currElevBot;
                dis.PolyZside(4,:,k) = currElevTop; 
            end

            for k = 1:dis.nlay+1
                currElev = reshape(dis.ELEV(:,:,k)',1,[]);
                dis.PolyZ(1,:,k) = currElev;
                dis.PolyZ(2,:,k) = currElev;
                dis.PolyZ(3,:,k) = currElev;
                dis.PolyZ(4,:,k) = currElev;
            end
%             FaceAlpha = .5;
         
        elseif MFin.laytyp == 1 % if unconfined
       
            for k = 1:dis.nlay
                
               
                currElevTop = SatThick(:,n);
                currElevBot = reshape(dis.ELEV(:,:,k+1),1,[]);

                dis.PolyZside(1,:,k) = currElevTop;
                dis.PolyZside(2,:,k) = currElevBot;
                dis.PolyZside(3,:,k) = currElevBot;
                dis.PolyZside(4,:,k) = currElevTop; 
            end

            for k = 1:dis.nlay+1
                
                if k == 1 

                    currElev = SatThick(:,n);

                else
             
                currElev = reshape(dis.ELEV(:,:,k),1,[]);               
                end
                dis.PolyZ(1,:,k) = currElev;
                dis.PolyZ(2,:,k) = currElev;
                dis.PolyZ(3,:,k) = currElev;
                dis.PolyZ(4,:,k) = currElev;
            end 
            
        end
     
            FaceAlpha = .2;
            EdgeAlpha = 0.1;
            patch(dis.PolyXsideL,dis.PolyYsideLR,initPscale*dis.PolyZside,[1 1 1],'FaceAlpha', FaceAlpha,'EdgeAlpha',EdgeAlpha,'Visible','on','Parent',MFax);
            hold(MFax,'on')
            patch(dis.PolyXsideR,dis.PolyYsideLR,initPscale*dis.PolyZside,[1 1 1],'FaceAlpha', FaceAlpha,'EdgeAlpha',EdgeAlpha,'Visible','on','Parent',MFax);  
            patch(dis.PolyXsideFB,dis.PolyYsideF,initPscale*dis.PolyZside,[1 1 1],'FaceAlpha', FaceAlpha,'EdgeAlpha',EdgeAlpha,'Visible','on','Parent',MFax);
            patch(dis.PolyXsideFB,dis.PolyYsideB,initPscale*dis.PolyZside,[1 1 1],'FaceAlpha', FaceAlpha,'EdgeAlpha',EdgeAlpha,'Visible','on','Parent',MFax);  
            patch(dis.PolyX,dis.PolyY,initPscale*dis.PolyZ(:,:,1),[1 1 1],'FaceAlpha', FaceAlpha,'EdgeAlpha',EdgeAlpha,'Visible','on','Parent',MFax);
            patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),[1 1 1],'FaceAlpha', FaceAlpha,'EdgeAlpha',EdgeAlpha,'Visible','on','Parent',MFax);
              patch(dis.PolyX,dis.PolyY,dis.PolyZtop,[1 1 1],'FaceAlpha', FaceAlpha,'EdgeAlpha',EdgeAlpha,'Visible','on','Parent',MFax);
end 
function MPtime_slider_Callback(source,events)
   
    
n = ceil(MPtime_slider.Value);
norig = n;
MPtime_slider_txt.String = ['Time Elapsed: \bf \it ', num2str(n*dis.perlen),' Days'];
n = n+1;

       if MFin.laytyp == 0 %if unconfined

            for k = 1:dis.nlay+1
                currElev = reshape(dis.ELEV(:,:,k)',1,[]);
                dis.PolyZ(1,:,k) = currElev;
                dis.PolyZ(2,:,k) = currElev;
                dis.PolyZ(3,:,k) = currElev;
                dis.PolyZ(4,:,k) = currElev;
            end
%             FaceAlpha = .5;
         
        elseif MFin.laytyp == 1 % if unconfined
            
            for k = 1:dis.nlay+1
                if k==1
                currElev = SatThick(:,n);
                else
                currElev = reshape(dis.ELEV(:,:,k)',1,[]);
                end
                dis.PolyZ(1,:,k) = currElev;
                dis.PolyZ(2,:,k) = currElev;
                dis.PolyZ(3,:,k) = currElev;
                dis.PolyZ(4,:,k) = currElev;
            end 
           
        end
    
        

        cla(MPax);
        axes(MPax);
        legend('off')
        
        
        FaceAlpha = 1;
        EdgeAlpha = 0.1;
        set(MPax,'XLim',[0 dis.Lx]); set(MPax,'YLim',[0 dis.Ly]); set(MPax,'ZLim',[0 1.05*max(max(max(dis.PolyZ)))]);
%         set(MPax,'XTickLabel',dis.xpos(dis.xposInd)); set(MPax,'YTickLabel',dis.ypos(dis.yposInd)); set(MPax,'ZTickLabel',{'Bottom layer 1','Top Layer 1'});
        patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),[1 1 1],'FaceAlpha',.2,'EdgeAlpha',EdgeAlpha,'Visible','on','Parent',MPax); 
        
        hold(MPax,'on');
     
        switch overlay_popup.Value
            case 1
            colormap(MPax,'parula');
            caxis(MPax,[Hmin,Hmax]);
            patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),disH.PolyZH(:,:,1,n),'FaceAlpha',FaceAlpha,'EdgeAlpha',EdgeAlpha,'Visible','on','Parent',MPax); 
            
            case 2
            colormap(MPax,summer(dis.nKvals));
            caxis(MPax,dis.Klim);   
            patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),disH.PolyZK,'FaceAlpha',FaceAlpha,'EdgeAlpha',EdgeAlpha,'Visible','on','Parent',MPax);
        end
        
        
        

        numstopWell  = find(stopZoneInd  == 3);
        numstopWellA = find(stopZoneIndA == 3); 
        numstopWellB = find(stopZoneIndB == 3);
        numstopWellC = find(stopZoneIndC == 3);

        numstopBound  = find(stopZoneInd  == 2); 
        numstopBoundA = find(stopZoneIndA == 2); 
        numstopBoundB = find(stopZoneIndB == 2);
        numstopBoundC = find(stopZoneIndC == 2);

        
        

        if isempty(find(status~=1))==1% find all particles that are not active at end of simulation
        
            numstop  = [];   
            numstopA = []; 
            numstopB = []; 
            numstopC = []; 

            numactive  = cumsum(ones(1,MPin.ParticleCount));
            numactiveA = cumsum(ones(1,MPin.ParticleCountA));
            numactiveB = cumsum(ones(1,MPin.ParticleCountB));
            numactiveC = cumsum(ones(1,MPin.ParticleCountC));
            
            wellstopA = 0;
            boundstopA = 0;
            activeA    = MPin.ParticleCountA;
            wellstopB = 0;
            boundstopB = 0;
            activeB   = MPin.ParticleCountB;
            wellstopC = 0;
            boundstopC = 0;
            activeC    = MPin.ParticleCountC;
        
        else
        numactive  = find(stopCntInd >=n);  
        numactiveA = find(stopCntIndA>=n);
        numactiveB = find(stopCntIndB>=n);
        numactiveC = find(stopCntIndC>=n);
        
        numstop  = find(stopCntInd < n);  
        numstopA = find(stopCntIndA< n); 
        numstopB = find(stopCntIndB< n); 
        numstopC = find(stopCntIndC< n);
        % for particle group A
        if isempty(numstopA)==0 
            for i = 1:length(numstopA)
                           
             if isempty(numstopWellA)==1 || isempty(find(numstopWellA== numstopA(i)))==1
                wellstopAind(i) = 0;
             else                
                wellstopAind(i)  = find(numstopWellA== numstopA(i));
             end

             if isempty(numstopBoundA)==1 || isempty(find(numstopBoundA==numstopA(i)))==1
                boundstopAind(i) = 0;
             else
                boundstopAind(i) = find(numstopBoundA==numstopA(i) );
             end            
             
            end
            
           boundstopA = sum(boundstopAind~=0);              
           wellstopA = sum(wellstopAind~=0) ;
           activeA    = MPin.ParticleCountA - (boundstopA + wellstopA);
            
              activeA    = MPin.ParticleCountA - (boundstopA + wellstopA);
                        
            
        else
            wellstopA = 0;
            boundstopA = 0;
            activeA    = MPin.ParticleCountA;
            
        end 
        
        %% for particle group B
        if isempty(numstopB)==0 
            for i = 1:length(numstopB)
                           
                if isempty(numstopWellB)==1 || isempty(find(numstopWellB == numstopB(i))) == 1
                    wellstopBind(i) = 0;
                else                
                    wellstopBind(i)  = find(numstopWellB == numstopB(i) );
                end

                if isempty(numstopBoundB)==1 || isempty(find(numstopBoundB == numstopB(i))) == 1
                    boundstopBind(i) = 0;
                else 
                    boundstopBind(i) = find(numstopBoundB == numstopB(i) );
                end            
             
            end
            
           boundstopB = sum(boundstopBind~=0);              
           wellstopB = sum(wellstopBind~=0) ;
           activeB    = MPin.ParticleCountB - (boundstopB + wellstopB);
            
%             wellstopB = sum(numel(wellstopBind));
%             boundstopB = sum(numel(boundstopBind));
%             activeB    = MPin.ParticleCountB - numel(numstopB);
            
        else
            wellstopB = 0;
            boundstopB = 0;
            activeB    = MPin.ParticleCountB;
            
        end
        
        % for particle group C
        
        if isempty(numstopC)==0

            for i = 1:length(numstopC)
                        
                 if isempty(numstopWellC)==1 || isempty(find(numstopWellC == numstopC(i)))==1
                    wellstopCind(i) = 0;
                 else                
                    wellstopCind(i)  = find(numstopWellC == numstopC(i) );
                 end

                 if isempty(numstopBoundC)==1 || isempty(find(numstopBoundC == numstopC(i)))==1
                    boundstopCind(i) = 0;                
                 else   
                    boundstopCind(i)  = find(numstopBoundC== numstopC(i));
                 end
            end  

           boundstopC = sum(boundstopCind~=0);              
           wellstopC = sum(wellstopCind~=0) ;
           activeC    = MPin.ParticleCountC - (boundstopC + wellstopC);
            
        else 
          
            wellstopC = 0;
            boundstopC = 0;
            activeC    = MPin.ParticleCountC ;           
            
        end 
        
        end
            
        wellstop = wellstopA + wellstopB +wellstopC ;
        boundstop = boundstopA + boundstopB +boundstopC ;
        active = activeA +activeB +activeC;
        
        particle_data = {activeA,wellstopA,boundstopA,MPin.ParticleCountA ; activeB,wellstopB,boundstopB,MPin.ParticleCountB ; activeC,wellstopC,boundstopC,MPin.ParticleCountC ; active,wellstop,boundstop,MPin.ParticleCount};
        Particle_data_table.Data = particle_data;
        
%         patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),[1 1 1],'FaceAlpha',.2,'EdgeAlpha',.2,'Visible','on','Parent',MPax);
          
   n = norig;

   

   
   if n >= 1 && hide_stop_well_check.Value == 1
    
      ParticlePosA =   scatter3(MPax,MP.PathsA(1,n,numactiveA),dis.Ly-MP.PathsA(2,n,numactiveA),MP.PathsA(3,n,numactiveA),10,dis.PcolorA,'filled');
      ParticlePosB =  scatter3(MPax,MP.PathsB(1,n,numactiveB),dis.Ly-MP.PathsB(2,n,numactiveB),MP.PathsB(3,n,numactiveB),10,dis.PcolorB,'filled');
      ParticlePosC =  scatter3(MPax,MP.PathsC(1,n,numactiveC),dis.Ly-MP.PathsC(2,n,numactiveC),MP.PathsC(3,n,numactiveC),10,dis.PcolorC,'filled');

   
            if n >= MFin.nper+1 && norig>0    %if slider is at final +1 th timestep
               % plot final particle positions
               ParticlePosA =  scatter3(MPax,MP.PathsA(1,end,numstopA),dis.Ly-MP.PathsA(2,end,numstopA),MP.PathsA(3,end,numstopA),10,dis.PcolorA,'filled');
               ParticlePosB =  scatter3(MPax,MP.PathsB(1,end,numstopB),dis.Ly-MP.PathsB(2,end,numstopB),MP.PathsB(3,end,numstopB),10,dis.PcolorB,'filled');
               ParticlePosC = scatter3(MPax,MP.PathsC(1,end,numstopC),dis.Ly-MP.PathsC(2,end,numstopC),MP.PathsC(3,end,numstopC),10,dis.PcolorC,'filled');   
            end
       
         if pathline_check.Value == 1 % plot active trajectories

           for i=1:length(numactiveA)
           plot3(MPax, [reshape(permute(MP.PathsA(1,1:n,numactiveA(i)),[3,1,2]),[],1)],[reshape(permute(dis.Ly-MP.PathsA(2,1:n,numactiveA(i)),[3,1,2]),[],1);],[reshape(permute(MP.PathsA(3,1:n,numactiveA(i)),[3,1,2]),[],1);],'Color',dis.PcolorA)
           end

           for i=1:length(numactiveB)
           plot3(MPax, [reshape(permute(MP.PathsB(1,1:n,numactiveB(i)),[3,1,2]),[],1)],[reshape(permute(dis.Ly-MP.PathsB(2,1:n,numactiveB(i)),[3,1,2]),[],1);],[reshape(permute(MP.PathsA(3,1:n,numactiveB(i)),[3,1,2]),[],1);],'Color',dis.PcolorB)
           end

           for i=1:length(numactiveC)
           plot3(MPax, [reshape(permute(MP.PathsC(1,1:n,numactiveC(i)),[3,1,2]),[],1)],[reshape(permute(dis.Ly-MP.PathsC(2,1:n,numactiveC(i)),[3,1,2]),[],1);],[reshape(permute(MP.PathsC(3,1:n,numactiveC(i)),[3,1,2]),[],1);],'Color',dis.PcolorC)
           end                             
         end
    
   elseif n >= 1 && hide_stop_well_check.Value == 0 % if hide_stop check value is 0;
        
      ParticlePosA = scatter3(MPax,MP.PathsA(1,n,:),dis.Ly-MP.PathsA(2,n,:),MP.PathsA(3,n,:),10,dis.PcolorA,'filled');
      ParticlePosB =scatter3(MPax,MP.PathsB(1,n,:),dis.Ly-MP.PathsB(2,n,:),MP.PathsB(3,n,:),10,dis.PcolorB,'filled');
      ParticlePosC =scatter3(MPax,MP.PathsC(1,n,:),dis.Ly-MP.PathsC(2,n,:),MP.PathsC(3,n,:),10,dis.PcolorC,'filled');
       
       if pathline_check.Value == 1  

               for i=1:MPin.ParticleCountA
                plot3(MPax, [reshape(permute(MP.PathsA(1,1:n,i),[3,1,2]),[],1)],[reshape(permute(dis.Ly-MP.PathsA(2,1:n,i),[3,1,2]),[],1);],[reshape(permute(MP.PathsA(3,1:n,i),[3,1,2]),[],1);],'Color',dis.PcolorA)
               end

               for i=1:MPin.ParticleCountB
                plot3(MPax, [reshape(permute(MP.PathsB(1,1:n,i),[3,1,2]),[],1)],[reshape(permute(dis.Ly-MP.PathsB(2,1:n,i),[3,1,2]),[],1);],[reshape(permute(MP.PathsA(3,1:n,i),[3,1,2]),[],1);],'Color',dis.PcolorB)
               end

               for i=1:MPin.ParticleCountC
                plot3(MPax, [reshape(permute(MP.PathsC(1,1:n,i),[3,1,2]),[],1)],[reshape(permute(dis.Ly-MP.PathsC(2,1:n,i),[3,1,2]),[],1);],[reshape(permute(MP.PathsC(3,1:n,i),[3,1,2]),[],1);],'Color',dis.PcolorC)
               end  
           
       end   
   end
   
   if n == 0 
      ParticlePosA = scatter3(MPax,MP.PathsA(1,1,:),dis.Ly-MP.PathsA(2,1,:),MP.PathsA(3,1,:),10,dis.PcolorA,'filled');
      ParticlePosB = scatter3(MPax,MP.PathsB(1,1,:),dis.Ly-MP.PathsB(2,1,:),MP.PathsB(3,1,:),10,dis.PcolorB,'filled');
      ParticlePosC = scatter3(MPax,MP.PathsC(1,1,:),dis.Ly-MP.PathsC(2,1,:),MP.PathsC(3,1,:),10,dis.PcolorC,'filled');
       
   end
   
   if well_check.Value == 1
   WellPosLine = plot3(MPax,[dis.xposCent(dis.Qcol) dis.xposCent(dis.Qcol)],[dis.yposCent(dis.Qrow) dis.yposCent(dis.Qrow)],[dis.LzBot,dis.LzTop],'Color',[1 0.2 0.2],'LineWidth',3);
   WellPosDot = scatter3(MPax,[dis.xposCent(dis.Qcol) ],[dis.yposCent(dis.Qrow) ],[dis.LzTop],100,[1 0.2 0.2],'filled','MarkerEdgeColor','Black','LineWidth',1.3);
   end  
  
end   
  

%save('tempMF','disH','mpath','MP')

mainfigH.Visible = 'on';
end



