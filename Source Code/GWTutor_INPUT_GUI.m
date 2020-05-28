function [ varargout] = GWTutor_INPUT_GUI(varargin)
% Author: Andy Banks 2019 - Univeristy of Kansas Dept of Geology 
% Handles plotting and GUI features for GWTutor Input screen  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ex1_tabs: Function For GWTutor Inuput GUI screen 

% Developed by Andy Banks with assistance from Mary Hill %%
% University of Kansas Department of Geology 2019 %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clc % clear command window 
clear % clear workspace 
close all % close all open figure windows

rng(7) %set random number generator seed


%%% Specify pwd by selecting location where modpath and modflow are located
executable_warning = 99; % 0 if all good, 1 of modflow is missing, 2 if ModPath is missing 
executables_path = uigetdir('C:\','Select location of MODFLOW and MODPATH executables');
addpath(executables_path);
cd(executables_path);
f = warndlg(executables_path);
if isfile('mf2005.exe') ==0
    str = 'MODFLOW executable mf2005.exe not found.';
    f = warndlg(str);
    executable_warning = 1;
    mainfig.Visible = 'off';
    %quit
else 
    executable_warning = 0;
end

if isfile('MPath7.exe') ==0
    str = 'MODPATH executable MPath7.exe not found.';
    f = warndlg(str)
    executable_warning = 1;
    mainfig.Visible = 'off';
    %quit
else 
    executable_warning = 0;
end


% add paths to directories containing modflow and modpath support libraries
%addpath(strcat(pwd,'\modflow')); 
%addpath(strcat(pwd,'\modpath'));


%% Initalize and populate main discretization structure (dis)
% this stores all relevant information time and space discretization parameters for the modflow model
% refer to the modflow 2005 documentation for more information on these parameters %%

%% Time Discretization %% 
dis.nper = 90; %number of stress periods.
dis.perlen = 4; % period length (days)
dis.nsteps = 10; %number of solver calls per step
dis.laytyp = 1; % modflow layer type 

%time units
dis.units.time = 'day';

%% Spatital Discretization %% 
dis.ncol = 30; 
dis.nrow = 20;
dis.nlay = 1;

%length units
dis.units.length = 'm';

dis.Lx = 650; % length of domian in X direction 
dis.Ly = 300;% length of domian in Y direction 
dis.LzTop = 300;%top elevation of domain
dis.LzBot = 0; % bottom elevation of domain 
dis.Lz = dis.LzTop-dis.LzBot; % total depth of aquifer 

% "aspect ratio" of model domain 
dis.LxNrm = (dis.Lx/max([dis.Lx,dis.Ly,dis.Lz]));
dis.LyNrm = (dis.Ly/max([dis.Lx,dis.Ly,dis.Lz]));
dis.LzNrm = abs((dis.Lz/max([dis.Lx,dis.Ly,dis.Lz])));

% row and col spacing 
dis.dc = (dis.Ly/dis.nrow)*ones(1,dis.nrow);%height of each col
dis.dr = (dis.Lx/dis.ncol)*ones(1,dis.ncol);%width of each row

dis.xpos = [0 cumsum(dis.dr)]; %x positon of column edges of each cell 
dis.ypos = [0 cumsum(dis.dc)]; %y positon of row edges of each cell 
dis.xposCent = cumsum(dis.dr)-dis.dr/2; % global x position of center of each cell 
dis.yposCent = cumsum(dis.dc)-dis.dc/2;  % global y position of center of each cell 

dis.xposInd = [(1:3:(dis.ncol)),dis.ncol+1 ]; % x ('row') indicies for each cell
dis.yposInd = [(1:3:(dis.nrow)),dis.nrow+1 ]; % y ('col') indicies for each cell

[dis.X , dis.Y, dis.Z] = meshgrid(dis.xpos, dis.ypos, sort([dis.LzBot dis.LzTop])); %grids of XY edge coordinates top layer 1
[dis.Xc , dis.Yc, dis.Zc] = meshgrid(dis.xposCent,dis.yposCent, sort([dis.LzBot dis.LzTop])); %grids of XY center coordiates top layer 1

%% boundary conditions %%
dis.ibound = ones(dis.nrow,dis.ncol,dis.nlay); %array specifying constant head (<0), inactive (=0) or active (>0)
dis.ibound(1,1:end) = 1; dis.ibound(end,1:end) = 1; % no boundary condition along E and W boundaries
dis.ibound(1:end,1) = -1; dis.ibound(1:end,end) = -1; % constant head boundaries along N and S boundaries 

%% Parameter Field Discretization%%

% hydraulic conductivity%
dis.KRbase = 1*ones(dis.nrow,dis.ncol,dis.nlay); %matrix containing Hydraulic conductivity in x-dir (L/T)
dis.KCbase = 1*ones(dis.nrow,dis.ncol,dis.nlay); %matrix containing Hydraulic conductivity in y-dir (L/T)
dis.KVbase = 1*ones(dis.nrow,dis.ncol,dis.nlay); %matrix containing Hydraulic conductivitu in z-dir (L/T)

% save base case hydraulic conductivities 
dis.KR = dis.KRbase; 
dis.KC = dis.KCbase;
dis.KV = dis.KVbase;

% form K fields for heterogeneous cases
dis.KHET1 = dis.KRbase; 
dis.KHET2 = dis.KRbase;
dis.KHET12 = dis.KRbase;
% add heterogeneity to KHET1 and KHET 2 
dis.KHET1([ceil(dis.nrow/2)-1:1:ceil(dis.nrow/2)+1],:) = 10; % heterogenous case one has a 3-cell wide stripe of high conductivity (10 times greater than the rest of the field) running N-S 
dis.KHET2(:,[ceil(dis.ncol/2)-1:1:ceil(dis.ncol/2)+1]) = .10; % heterogenous case two has a 3-cell wide stripe of low conductivity (10 times lower than the rest of the field) running E-W

% heterogenous case three (KHET12) has a the heterogeneity from cases 1 and
% two superimposed on another 
dis.KHET12([ceil(dis.nrow/2)-1:1:ceil(dis.nrow/2)+1],:) = 10;
dis.KHET12(:,[ceil(dis.ncol/2)-1:1:ceil(dis.ncol/2)+1])= .10;

% set initial value for scaling hydraulic conductivity fields
dis.Kinit = 1;


% recharge  
dis.RCHbase = zeros(dis.nrow,dis.ncol,dis.nlay); % matrix containingrecharge for each cell 
dis.RCH = dis.RCHbase;
dis.RCHinit = 0; % initial value of recharge 

% elevation 
dis.ELEVbase = zeros(dis.nrow,dis.ncol,dis.nlay+1); % matrix containing bottom elevations for all cells
dis.ELEVbase(:,:,2) = dis.LzBot; %bottom elevation for all cells in layer 1
dis.ELEVbase(:,:,1) = dis.LzTop; %bottom elevation for all cells in layer 1

dis.ELEVinit = dis.LzTop; % initial top elevation of each cell when GUI appears
dis.dvbase = abs(dis.ELEVbase(:,:,1)-dis.ELEVbase(:,:,2)); % layer thickness each cell 

dis.ELEV = dis.ELEVbase; % current  elevation of all cells (this term gets updated by the user when changng the top elevation of the aquifer) 
dis.dv = abs(dis.ELEV(:,:,1)-dis.ELEV(:,:,2)); % current thickness of all cells (also gets updated by user when changng the top elevation of the aquifer) 
dis.ELEVtop = reshape(dis.ELEVbase(:,:,1)',[],1); % current top elevation of all cells  (used for drawing cell polygons in heads window)

%specific storage 
dis.SSbase = ones(dis.nrow,dis.ncol,dis.nlay); % matrix containing  specific storage (1/m) for each cell;
dis.SSinit = 1E-5 % set initial specific storage 
dis.SS = dis.SSinit*dis.SSbase; %set initial specific storage ;


%specific yeild 
dis.SYbase = ones(dis.nrow,dis.ncol,dis.nlay);% matrix containing specific yeild for each cell
dis.SYinit = 0.2;% set initial specific yield 
dis.SY = dis.SYinit*dis.SYbase; %update Specific yeild (dimensionless);
dis.S = dis.SS.*dis.dv+dis.SY; %compute storativity S= SS*dv +Sy;

% porosity 
dis.PorosityBase = ones(dis.nrow,dis.ncol,dis.nlay); % matrix containing porosity for each cell
dis.Pinit = 0.25; % set initial porosity 
dis.Porosity = dis.Pinit*dis.PorosityBase; %update porosity

% pumping
dis.Qcol = dis.ncol - 8; %row position of single pumping well
dis.Qrow = ceil(dis.nrow/2); % row position of single pumping well
dis.Qind = sub2ind([dis.ncol,dis.nrow,dis.nlay],dis.Qcol,dis.Qrow); % convert rc index to matrix index 

dis.qinit = -1E2; % initial Q rate 
dis.q = dis.qinit; % set current q (gets modified by user when changing pumping rates)) 
dis.qref =  log10(abs(dis.q)); % convert to log scale
dis.Qbase = zeros(dis.nrow,dis.ncol,dis.nlay); % matrix containing Q values for each cell (only cell with non zero value is that corresponding to the well) 
dis.Qbase(dis.Qrow,dis.Qcol) = dis.q; % populate with Q from single well
dis.Q = dis.Qbase; % set current q matrix ( gets updated by user when changing pumping rates) 

% build reference q matrix -- used when the user presses the reset button
dis.QbaseREF = zeros(dis.nrow,dis.ncol,dis.nlay); 
dis.QbaseREF(dis.Qrow,dis.Qcol) = dis.qref;
dis.QREF = dis.QbaseREF;


%initial head distribution 
hedge = 200; % head on the North edge
dis.H = 190*ones(dis.nrow,dis.ncol,dis.nlay); %Initial head of 190 for all cells 
dis.H = dis.H(:,:,1);

dis.H(1:end,1) = hedge; dis.H(1:end,end) = hedge-20; % mage head difference of 20m between N and S boundaries (head is 190 everywhere else) 
dis.Hmax = max(max(max(dis.H))); % current maximum head value (for scaling axis) 
dis.Hmin = min(min(min(dis.H))); % current minimum head value (for scaling axis) 
dis.LhNrm = abs((dis.Hmax/max([dis.Lx,dis.Ly,dis.Lz,dis.Hmax]))); % aspect ratio of heads axis 

% determine if cells are saturated or not (unsaturated if head is greater than aquifer top elevation)
if dis.LzTop>dis.Hmax
dis.ELEVsat = reshape(dis.H',[],1);   %if saturated, these elevations are used  
end






    
%% Make tabs for INPUT GUI 
% each tab contains relevant information about the model. Each tab has an
% axis and several buttons assocaited with it. Each button references a
% callback function. 

% init figure and axis
mainfig = figure('Visible','off','Position',[0 0 1000 1000],'Name','GroundWater Tutor -- Input','NumberTitle','off');
mainax = axes('Visible','on','Units','Normalized','position',[0.15 0.15  .6 .6],'Color','none','YDir','reverse','XAxisLocation','top','TickDir','out','PlotBoxAspectRatio',[dis.LxNrm dis.LyNrm dis.LzNrm],'FontSize',8,'LabelFontSizeMultiplier',1.5); 


% params for axis on each tab
AxVisible = 'off';
AxUnits = 'normalized';
AxPosition = [0.18 0.14  .6 .6];
AxColor = 'none';
AxYdir = 'reverse';
AxXAxisLocation = 'top';
AxTickDir = 'out';
AxPlotBoxAspectRatio = [dis.LxNrm dis.LyNrm 0.05];
AxFontSize = 8;
AxLabelFontSizeMultiplier = 1.5; 
AxTitleFontSizeMultiplier = 2;
AxCameraUpVector = [0    -1     0];
AxCameraPosition =   1.0e+03*[ 2.6028    3.0239    1.5190];
tgroupInit = uitabgroup('Parent',mainfig);

% each tab has its own axis

% bouundary conditions tab 
iboundTab = uitab('Parent', tgroupInit, 'Title', 'Boundary Conditions');
iboundax = axes('Visible',AxVisible,'Units',AxUnits,'position',AxPosition,'Color',AxColor,'YDir',AxYdir,'XAxisLocation',AxXAxisLocation,'TickDir',AxTickDir,'PlotBoxAspectRatio',[AxPlotBoxAspectRatio(1:2), 0.6],'FontSize',AxFontSize,'LabelFontSizeMultiplier',AxLabelFontSizeMultiplier,'CameraUpVector',AxCameraUpVector,'CameraPosition',AxCameraPosition);
iboundax.Parent = iboundTab;
set(gca,'color','none') 

% initial conditions (aquifer elevation) tab 
initialTab = uitab('Parent', tgroupInit, 'Title', 'Initial Conditions');
initialax = axes('Visible',AxVisible,'Units',AxUnits,'position',[0.18 0.14  .6 .6],'Color',AxColor,'YDir',AxYdir,'XAxisLocation',AxXAxisLocation,'TickDir',AxTickDir,'PlotBoxAspectRatio',AxPlotBoxAspectRatio,'FontSize',AxFontSize,'LabelFontSizeMultiplier',AxLabelFontSizeMultiplier);
initialax.Parent = initialTab;
set(gca,'color','none') 

% aquifer parameters tab (hydraulic conductivity, storage, porosity)
paramsTab = uitab('Parent', tgroupInit, 'Title','Parameters');
paramsax = axes('Visible',AxVisible,'Units',AxUnits,'position',AxPosition,'Color',AxColor,'YDir',AxYdir,'XAxisLocation',AxXAxisLocation,'TickDir',AxTickDir,'PlotBoxAspectRatio',AxPlotBoxAspectRatio,'FontSize',AxFontSize,'LabelFontSizeMultiplier',AxLabelFontSizeMultiplier);
paramsax.Parent = paramsTab;
set(gca,'color','none') 

% sources tab ( pumping from single well and uniform surface recharge) 
sourceTab = uitab('Parent', tgroupInit, 'Title','Pumping & Recharge');
sourceax = axes('Visible',AxVisible,'Units',AxUnits,'position',AxPosition,'Color',AxColor,'YDir',AxYdir,'XAxisLocation',AxXAxisLocation,'TickDir',AxTickDir,'PlotBoxAspectRatio',AxPlotBoxAspectRatio,'FontSize',AxFontSize,'LabelFontSizeMultiplier',AxLabelFontSizeMultiplier);
sourceax.Parent = sourceTab;
set(gca,'color','none') 

% time discretization and genereal model overview tab
runMFTab = uitab('Parent', tgroupInit, 'Title', 'Run MODFLOW/MODPATH ');
runMFax = axes('Visible',AxVisible,'Units',AxUnits,'position',AxPosition,'Color',AxColor,'YDir',AxYdir,'XAxisLocation',AxXAxisLocation,'TickDir',AxTickDir,'PlotBoxAspectRatio',[AxPlotBoxAspectRatio(1:2), 0.6],'FontSize',AxFontSize,'LabelFontSizeMultiplier',AxLabelFontSizeMultiplier,'TitleFontSizeMultiplier',AxTitleFontSizeMultiplier); 
runMFax.Parent = runMFTab;
set(gca,'color','none') 

%% add image to prompt rotation feature 
% image (RotateButton.jpg) is placed on its own axis 
rotbutax = axes('Visible','on','parent',iboundTab,'Position',[0.1,0.9,0.03,0.03],'units','normalized','Color',get(gcf,'Color'),'XColor',get(gcf,'Color'),'YColor',get(gcf,'Color'),'ZColor',get(gcf,'Color'));
rotImg = imread('RotateButton.JPG');
imshow(rotImg,'parent',rotbutax);
rotbutTxt =  annotation(iboundTab,'textbox','Position',[.13 .828 .1 .1],'Units','normalized','String',[' Rotate Button Located in Toolbar'],'Visible','on','EdgeColor','none','FontSize',10);
get(rotbutTxt,'Position')
%% make compass on bottom left corner of each tab (shows cardinal directions as model is rotated) 
% display parameters 
CompassAxVisible = 'off';
CompassAxUnits = 'normalized';
CompassAxPosition = [0.8 0.1  .1 .1];
CompassAxColor = get(gcf,'Color');
CompassAxYdir = 'reverse';
CompassAxXAxisLocation = 'bottom';
CompassAxTickDir = 'out';
CompassAxPlotBoxAspectRatio = [1 1 1];
CompassAxFontSize = 8;
CompassAxLabelFontSizeMultiplier = 1.5; 
CompassAxTitleFontSizeMultiplier = 2;
CompassAxCameraUpVector = [0    0     0];
CompassAxCameraPosition = 1.0e+03*[  2.0812    3.0980    1.8423];
compassfont = 8;

iboundcompass =  axes('Visible',CompassAxVisible); % compass for boundary conditions tab
initialcompass   =  axes('Visible',CompassAxVisible);% compass for initial conditions  (aquifer elevation) tab
paramscompass  =  axes('Visible',CompassAxVisible);% compass for parameters tab
sourcecompass =  axes('Visible',CompassAxVisible);% compass for source terms tab
runMFcompass  =  axes('Visible',CompassAxVisible);% compass for time discretization and general model overview tab 

% format compass for boundary conditions tab
axes(iboundcompass);
NS = plot3(iboundcompass,[0.5 0.5],[0.2 0.8],[.5 .5],'Color','Black','LineWidth',2);
hold(iboundcompass,'on')
EW = plot3(iboundcompass,[0.2 0.8],[0.5 0.5],[.5 .5],'Color','Black','LineWidth',2);
North = text(0.5,0,0.5,'N','FontSize',compassfont);
South = text(0.5,1,0.5,'S','FontSize',compassfont);
East = text(0,0.5,0.5,'E','FontSize',compassfont);
West = text(1,0.5,0.5,'W','FontSize',compassfont);
set(iboundcompass,'Visible',CompassAxVisible,'Units',CompassAxUnits,'position',CompassAxPosition,'Color',CompassAxColor,'YDir',CompassAxYdir,'XAxisLocation',CompassAxXAxisLocation,'TickDir',CompassAxTickDir,'PlotBoxAspectRatio',CompassAxPlotBoxAspectRatio,'FontSize',CompassAxFontSize,'LabelFontSizeMultiplier',CompassAxLabelFontSizeMultiplier,'CameraUpVector',CompassAxCameraUpVector,'CameraPosition',CompassAxCameraPosition);
set(iboundcompass,'Parent' ,iboundTab,'XTick',[],'YTick',[],'ZTick',[],'XLim',[0 1],'YLim',[0 1],'ZLim',[0 1],'XColor',get(gcf,'Color'),'YColor',get(gcf,'Color'),'ZColor',get(gcf,'Color'));
iboundLink = linkprop([iboundcompass,iboundax],{'CameraUpVector','CameraPosition'}); % link compass axis to main axis in tab 
setappdata(iboundTab, 'StoreTheLink', iboundLink);% link compass axis to main axis in tab

% format compass for initial conditions  (aquifer elevation) tab
axes(initialcompass);
NS = plot3(initialcompass,[0.5 0.5],[0.2 0.8],[.5 .5],'Color','Black','LineWidth',2);
hold(initialcompass,'on')
EW = plot3(initialcompass,[0.2 0.8],[0.5 0.5],[.5 .5],'Color','Black','LineWidth',2);
North = text(0.5,0,0.5,'N','FontSize',compassfont);
South = text(0.5,1,0.5,'S','FontSize',compassfont);
East = text(0,0.5,0.5,'E','FontSize',compassfont);
West = text(1,0.5,0.5,'W','FontSize',compassfont);
set(initialcompass,'Visible',CompassAxVisible,'Units',CompassAxUnits,'position',CompassAxPosition,'Color',CompassAxColor,'YDir',CompassAxYdir,'XAxisLocation',CompassAxXAxisLocation,'TickDir',CompassAxTickDir,'PlotBoxAspectRatio',CompassAxPlotBoxAspectRatio,'FontSize',CompassAxFontSize,'LabelFontSizeMultiplier',CompassAxLabelFontSizeMultiplier,'CameraUpVector',CompassAxCameraUpVector,'CameraPosition',CompassAxCameraPosition);
set(initialcompass,'Parent' ,initialTab,'XTick',[],'YTick',[],'ZTick',[],'XLim',[0 1],'YLim',[0 1],'ZLim',[0 1],'XColor',get(gcf,'Color'),'YColor',get(gcf,'Color'),'ZColor',get(gcf,'Color'));
initialLink = linkprop([initialcompass,initialax],{'CameraUpVector','CameraPosition'});% link compass axis to main axis in tab
setappdata(initialTab, 'StoreTheLink', initialLink);% link compass axis to main axis in tab

% format compass for parameters tab
axes(paramscompass);
NS = plot3(paramscompass,[0.5 0.5],[0.2 0.8],[.5 .5],'Color','Black','LineWidth',2);
hold(paramscompass,'on')
EW = plot3(paramscompass,[0.2 0.8],[0.5 0.5],[.5 .5],'Color','Black','LineWidth',2);
North = text(0.5,0,0.5,'N','FontSize',compassfont);
South = text(0.5,1,0.5,'S','FontSize',compassfont);
East = text(0,0.5,0.5,'E','FontSize',compassfont);
West = text(1,0.5,0.5,'W','FontSize',compassfont);
set(paramscompass,'Visible',CompassAxVisible,'Units',CompassAxUnits,'position',CompassAxPosition,'Color',CompassAxColor,'YDir',CompassAxYdir,'XAxisLocation',CompassAxXAxisLocation,'TickDir',CompassAxTickDir,'PlotBoxAspectRatio',CompassAxPlotBoxAspectRatio,'FontSize',CompassAxFontSize,'LabelFontSizeMultiplier',CompassAxLabelFontSizeMultiplier,'CameraUpVector',CompassAxCameraUpVector,'CameraPosition',CompassAxCameraPosition);
set(paramscompass,'Parent' ,paramsTab,'XTick',[],'YTick',[],'ZTick',[],'XLim',[0 1],'YLim',[0 1],'ZLim',[0 1],'XColor',get(gcf,'Color'),'YColor',get(gcf,'Color'),'ZColor',get(gcf,'Color'));
paramsLink = linkprop([paramscompass,paramsax],{'CameraUpVector','CameraPosition'});% link compass axis to main axis in tab
setappdata(paramsTab, 'StoreTheLink', paramsLink);% link compass axis to main axis in tab

% format compass for source terms tab
axes(sourcecompass);
NS = plot3(sourcecompass,[0.5 0.5],[0.2 0.8],[.5 .5],'Color','Black','LineWidth',2);
hold(sourcecompass,'on')
EW = plot3(sourcecompass,[0.2 0.8],[0.5 0.5],[.5 .5],'Color','Black','LineWidth',2);
North = text(0.5,0,0.5,'N','FontSize',compassfont);
South = text(0.5,1,0.5,'S','FontSize',compassfont);
East = text(0,0.5,0.5,'E','FontSize',compassfont);
West = text(1,0.5,0.5,'W','FontSize',compassfont);
set(sourcecompass,'Visible',CompassAxVisible,'Units',CompassAxUnits,'position',CompassAxPosition,'Color',CompassAxColor,'YDir',CompassAxYdir,'XAxisLocation',CompassAxXAxisLocation,'TickDir',CompassAxTickDir,'PlotBoxAspectRatio',CompassAxPlotBoxAspectRatio,'FontSize',CompassAxFontSize,'LabelFontSizeMultiplier',CompassAxLabelFontSizeMultiplier,'CameraUpVector',CompassAxCameraUpVector,'CameraPosition',CompassAxCameraPosition);
set(sourcecompass,'Parent' ,sourceTab,'XTick',[],'YTick',[],'ZTick',[],'XLim',[0 1],'YLim',[0 1],'ZLim',[0 1],'XColor',get(gcf,'Color'),'YColor',get(gcf,'Color'),'ZColor',get(gcf,'Color'));
sourceLink = linkprop([sourcecompass,sourceax],{'CameraUpVector','CameraPosition'});% link compass axis to main axis in tab
setappdata(sourceTab, 'StoreTheLink', sourceLink);% link compass axis to main axis in tab

% format compass for time discretization and general model overview tab 
axes(runMFcompass);
NS = plot3(runMFcompass,[0.5 0.5],[0.2 0.8],[.5 .5],'Color','Black','LineWidth',2);
hold(runMFcompass,'on')
EW = plot3(runMFcompass,[0.2 0.8],[0.5 0.5],[.5 .5],'Color','Black','LineWidth',2);
North = text(0.5,0,0.5,'N','FontSize',compassfont);
South = text(0.5,1,0.5,'S','FontSize',compassfont);
East = text(0,0.5,0.5,'E','FontSize',compassfont);
West = text(1,0.5,0.5,'W','FontSize',compassfont);
set(runMFcompass,'Visible',CompassAxVisible,'Units',CompassAxUnits,'position',CompassAxPosition,'Color',CompassAxColor,'YDir',CompassAxYdir,'XAxisLocation',CompassAxXAxisLocation,'TickDir',CompassAxTickDir,'PlotBoxAspectRatio',CompassAxPlotBoxAspectRatio,'FontSize',CompassAxFontSize,'LabelFontSizeMultiplier',CompassAxLabelFontSizeMultiplier,'CameraUpVector',CompassAxCameraUpVector,'CameraPosition',CompassAxCameraPosition);
set(runMFcompass,'Parent' ,runMFTab,'XTick',[],'YTick',[],'ZTick',[],'XLim',[0 1],'YLim',[0 1],'ZLim',[0 1],'XColor',get(gcf,'Color'),'YColor',get(gcf,'Color'),'ZColor',get(gcf,'Color'));
runMFLink = linkprop([runMFcompass,runMFax],{'CameraUpVector','CameraPosition'});% link compass axis to main axis in tab
setappdata(runMFTab, 'StoreTheLink', runMFLink);% link compass axis to main axis in tab


%% set axes limits and labels with loop (generics)
axNames = {'runMFax','iboundax','initialax','paramsax','sourceax'};
axTitle = {'Modflow','Spatial Discretization','Boundary Conditions','Initial Hydraulic Head Distribution','Spatial Paramaters (Time Invariant) ',' Pumping and Recharge'};   

for name = 1:length(axNames)
    cmdXLim = strjoin({'set(',cell2mat(axNames(name)),', ''XLim'', [',num2str(0),' ', num2str(dis.Lx),'])'},'');
    cmdYLim = strjoin({'set(',cell2mat(axNames(name)),', ''YLim'', [',num2str(0),' ', num2str(dis.Ly),'])'},'');
    cmdZLim = strjoin({'set(',cell2mat(axNames(name)),', ''ZLim'', sort([',num2str(dis.LzBot),' ', num2str(dis.LzTop),']))'},'');
    
    cmdXTick = strjoin({'set(',cell2mat(axNames(name)),', ''XTick'', dis.xposCent)'},'');
    cmdYTick = strjoin({'set(',cell2mat(axNames(name)),', ''YTick'', dis.yposCent)'},'');
    cmdZTick = strjoin({'set(',cell2mat(axNames(name)),', ''ZTick'', sort([',num2str(dis.LzBot),' ', num2str(dis.LzTop),']))'},'');
       
    cmdXTickLabel = strjoin({'set(',cell2mat(axNames(name)),', ''XTickLabel'', [1:1:dis.ncol])'},'');
    cmdYTickLabel = strjoin({'set(',cell2mat(axNames(name)),', ''YTickLabel'', [1:1:dis.nrow])'},'');
    cmdZTickLabel = strjoin({'set(',cell2mat(axNames(name)),', ''ZTickLabel'',{''Bot Layer 1'',''Top Layer 1''})'},'');
    
    cmdxlabel = strjoin({'xlabel(',cell2mat(axNames(name)),',''Column  (X)'')'},'');
    cmdylabel = strjoin({'ylabel(',cell2mat(axNames(name)),',''Row  (Y)'')'},'');
    cmdzlabel = strjoin({'zlabel(',cell2mat(axNames(name)),',''Layer  (Z)'')'},'');
    
    XYaxNames = {'runMFax','initialax','paramsax','sourceax'};
 
    for j = 1:length(XYaxNames)
        
        if  isequal(axNames(name),XYaxNames(j))==1 
            cmdXTick = strjoin({'set(',cell2mat(axNames(name)),', ''XTick'', dis.xpos(dis.xposInd))'},'');
            cmdYTick = strjoin({'set(',cell2mat(axNames(name)),', ''YTick'', dis.ypos(dis.yposInd))'},'');
            cmdZTick = strjoin({'set(',cell2mat(axNames(name)),', ''ZTick'', [dis.LzBot,  dis.LzTop])'},'');
            
            cmdXTickLabel = strjoin({'set(',cell2mat(axNames(name)),', ''XTickLabel'', dis.xpos(dis.xposInd))'},'');
            cmdYTickLabel = strjoin({'set(',cell2mat(axNames(name)),', ''YTickLabel'', dis.ypos(dis.yposInd))'},'');
            cmdZTickLabel = strjoin({'set(',cell2mat(axNames(name)),', ''ZTickLabel'', [dis.LzBot, dis.LzTop])'},'');

            cmdxlabel = strjoin({'xlabel(',cell2mat(axNames(name)),',''X_d_i_s_t  (m)'')'},'');
            cmdylabel = strjoin({'ylabel(',cell2mat(axNames(name)),',''Y_d_i_s_t (m)'')'},'');
            cmdzlabel = strjoin({'zlabel(',cell2mat(axNames(name)),',''Z_d_i_s_t (m)'')'},'');
              
        end
        
        eval(cmdXTick); eval(cmdYTick); eval(cmdZTick);
        eval(cmdXTickLabel); eval(cmdYTickLabel); eval(cmdZTickLabel);
        eval(cmdxlabel); eval(cmdylabel); eval(cmdzlabel);

    end
    
    eval(cmdXLim); eval(cmdYLim); eval(cmdZLim);
    eval(cmdXTick); eval(cmdYTick); eval(cmdZTick);
    eval(cmdXTickLabel); eval(cmdYTickLabel); eval(cmdZTickLabel);
    eval(cmdxlabel); eval(cmdylabel); eval(cmdzlabel);
end

% change axes limits for aquifer elevation axis (scale elvation to head surface)
dis.initPscale = 1;
if dis.LzTop >=dis.Hmax
set(initialax,'ZLim',[dis.LzBot , 1.001*dis.LzTop],'ZTick',[dis.LzBot ,  dis.Hmin dis.Hmax ,dis.LzTop,],'ZTickLabel',{['(Bot Layer 1)  ',num2str(dis.LzBot)],num2str(dis.Hmin), num2str(dis.Hmax),['(Top Layer 1)  ',num2str(dis.LzTop)]},'PlotBoxAspectRatio',[dis.LxNrm dis.LyNrm 0.6]);     
set(iboundax,'ZLim',[dis.LzBot , 1.001*dis.LzTop],'ZTick',[dis.LzBot ,  dis.Hmin dis.Hmax ,dis.LzTop,],'ZTickLabel',{['(Bot Layer 1)  ',num2str(dis.LzBot)],num2str(dis.Hmin), num2str(dis.Hmax),['(Top Layer 1)  ',num2str(dis.LzTop)]},'PlotBoxAspectRatio',[dis.LxNrm dis.LyNrm 0.6]);     
else
set(initialax,'ZLim',[dis.LzBot , 1.5*dis.Hmax],'ZTick',[dis.LzBot , dis.initPscale*dis.LzTop, dis.Hmin dis.Hmax],'ZTickLabel',{['(Bot Layer 1)  ',num2str(dis.LzBot)],['(Top Layer 1)  ',num2str(dis.LzTop)],num2str(dis.Hmin), num2str(dis.Hmax)},'PlotBoxAspectRatio',[dis.LxNrm dis.LyNrm 0.6]);
set(iboundax,'ZLim',[dis.LzBot , 1.5*dis.Hmax],'ZTick',[dis.LzBot , dis.initPscale*dis.LzTop, dis.Hmin dis.Hmax],'ZTickLabel',{['(Bot Layer 1)  ',num2str(dis.LzBot)],['(Top Layer 1)  ',num2str(dis.LzTop)],num2str(dis.Hmin), num2str(dis.Hmax)},'PlotBoxAspectRatio',[dis.LxNrm dis.LyNrm 0.6]);
end
zlabel(initialax,'Z_d_i_s_t (m)');

%% call polygon function 
[dis] = drawPolys(dis); % returns modified dis strutcute with fields containg polygons for each 3-D model parameter  


%% plot grid cells using polygon verticies 

% plotting parameters 
edgealpha = 1;
facealpha = 0.5;
satColor = [0.1 0.5 1];
satfacealpha = 0.05;
sideedgealpha = 0.2;
sidefacealpha = 0.25;

% plot each edge (left,right,forward,backward,top,bot,top2) of each cell
% (top and top2 are either the top elevation of the aquifer or th saturated
% thickness of the aquifer, depending on which is greater (top2 is always
% the upper most surface)

% plot polygons for the runMF axis (time discretization and general model
% information) 
plt.XYZleft = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.PolyZside,satColor,'FaceAlpha',sidefacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',sideedgealpha);
plt.XYZright = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.PolyZside,satColor,'FaceAlpha',sidefacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',sideedgealpha);  
plt.XYZfor = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.PolyZside,satColor,'FaceAlpha',sidefacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',sideedgealpha);
plt.XYZback = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.PolyZside,satColor,'FaceAlpha',sidefacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',sideedgealpha);  
plt.XYZtop = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),satColor,'FaceAlpha',0.7,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
plt.XYZbot = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),satColor,'FaceAlpha',0.7,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
plt.XYZtop2 = patch(dis.PolyX,dis.PolyY,1.1*dis.PolyZtop(:,:,1),satColor,'FaceAlpha',0.2,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
hold(runMFax,'on') % hold axis
dis.Hbig = resizem(dis.H,[length(dis.ypos),length(dis.xpos)]); % poygons for potentiometric surface 
plt.surfHrunMF = surf(runMFax,dis.X(:,:,1),dis.Y(:,:,1),dis.Hbig,'EdgeAlpha',0.2,'FaceAlpha',0.5,'Visible','on');% overlay plot of potentiometric surface 

% plotting params
edgealpha = 0.1;
edgeindexFB = zeros(1,dis.ncol);
edgeindexFB([1,end]) = -1;
%% plot polygons for boundary conditions  
plt.XYZleftIbound = patch(dis.PolyXsideL(:,[1:dis.ncol:dis.nrow*dis.ncol]),dis.PolyYsideLR(:,[1:dis.ncol:dis.nrow*dis.ncol]),dis.PolyZside(:,[1:dis.ncol:dis.nrow*dis.ncol]),-1,'FaceAlpha',0.9,'Visible','on','Parent',iboundax,'EdgeAlpha',edgealpha);
plt.XYZrightIbound = patch(dis.PolyXsideR(:,[end:-dis.ncol:1]),dis.PolyYsideLR(:,[end:-dis.ncol:1]),dis.PolyZside(:,[end:-dis.ncol:1]),-1,'FaceAlpha',0.9,'Visible','on','Parent',iboundax,'EdgeAlpha',edgealpha);  
plt.XYZforIbound = patch(dis.PolyXsideFB(:,[1:dis.ncol]),dis.PolyYsideF(:,[1:dis.ncol]),dis.PolyZside(:,[1:dis.ncol]),edgeindexFB,'FaceAlpha',0.9,'Visible','on','Parent',iboundax,'EdgeAlpha',edgealpha);
plt.XYZbackIbound = patch(dis.PolyXsideFB(:,[end-dis.ncol+1:end]),dis.PolyYsideB(:,[end-dis.ncol+1:end]),dis.PolyZside(:,[end-dis.ncol+1:end]),edgeindexFB,'FaceAlpha',0.9,'Visible','on','Parent',iboundax,'EdgeAlpha',edgealpha);  
plt.XYZtopIbound = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),dis.PolyZibound,'FaceAlpha',1,'Visible','on','Parent',iboundax,'EdgeAlpha',edgealpha);
plt.XYZbotIbound = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),dis.PolyZibound,'FaceAlpha',1,'Visible','on','Parent',iboundax,'EdgeAlpha',edgealpha);

%% plot polygons for recharge 
facealpha = 0.5;
plt.XYZleftRCH = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.PolyZside,dis.PolyZrch,'FaceAlpha',facealpha,'Visible','on','Parent',sourceax,'EdgeAlpha',edgealpha);
plt.XYZrightRCH = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.PolyZside,dis.PolyZrch,'FaceAlpha',facealpha,'Visible','on','Parent',sourceax,'EdgeAlpha',edgealpha);  
plt.XYZforRCH = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.PolyZside,dis.PolyZrch,'FaceAlpha',facealpha,'Visible','on','Parent',sourceax,'EdgeAlpha',edgealpha);
plt.XYZbackRCH = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.PolyZside,dis.PolyZrch,'FaceAlpha',facealpha,'Visible','on','Parent',sourceax,'EdgeAlpha',edgealpha);  
plt.XYZtopRCH = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),dis.PolyZrch,'FaceAlpha',1,'Visible','on','Parent',sourceax,'EdgeAlpha',edgealpha);
plt.XYZbotRCH = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),dis.PolyZrch,'FaceAlpha',1,'Visible','on','Parent',sourceax,'EdgeAlpha',edgealpha);

%% plot polygons for rpumpage 
facealpha = 0.5;
plt.XYZleftQ = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.PolyZside,dis.PolyZQ,'FaceAlpha',facealpha,'Visible','off','Parent',sourceax,'EdgeAlpha',edgealpha);
plt.XYZrightQ = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.PolyZside,dis.PolyZQ,'FaceAlpha',facealpha,'Visible','off','Parent',sourceax,'EdgeAlpha',edgealpha);  
plt.XYZforQ = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.PolyZside,dis.PolyZQ,'FaceAlpha',facealpha,'Visible','off','Parent',sourceax,'EdgeAlpha',edgealpha);
plt.XYZbackQ = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.PolyZside,dis.PolyZQ,'FaceAlpha',facealpha,'Visible','off','Parent',sourceax,'EdgeAlpha',edgealpha);  
plt.XYZtopQ = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),dis.PolyZQ,'FaceAlpha',1,'Visible','off','Parent',sourceax,'EdgeAlpha',edgealpha);
plt.XYZbotQ = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),dis.PolyZQ,'FaceAlpha',1,'Visible','off','Parent',sourceax,'EdgeAlpha',edgealpha);

%% plot polygons for hydraulic conductivity 
plt.XYZleftKr = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.PolyZside,dis.PolyZkr,'FaceAlpha',0.7,'Visible','on','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZrightKr = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.PolyZside,dis.PolyZkr,'FaceAlpha',0.7,'Visible','on','Parent',paramsax,'EdgeAlpha',edgealpha);  
plt.XYZforKr = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.PolyZside,dis.PolyZkr,'FaceAlpha',0.7,'Visible','on','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZbackKr = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.PolyZside,dis.PolyZkr,'FaceAlpha',0.7,'Visible','on','Parent',paramsax,'EdgeAlpha',edgealpha);  
plt.XYZtopKr = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),dis.PolyZkr,'FaceAlpha',1,'Visible','on','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZbotKr = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),dis.PolyZkr,'FaceAlpha',1,'Visible','on','Parent',paramsax,'EdgeAlpha',edgealpha);

plt.XYZleftKc = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.PolyZside,dis.PolyZkc,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZrightKc = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.PolyZside,dis.PolyZkc,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);  
plt.XYZforKc = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.PolyZside,dis.PolyZkc,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZbackKc = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.PolyZside,dis.PolyZkc,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);  
plt.XYZtopKc = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),dis.PolyZkc,'FaceAlpha',1,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZbotKc = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),dis.PolyZkc,'FaceAlpha',1,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);

plt.XYZleftKv = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.PolyZside,dis.PolyZkv,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZrightKv = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.PolyZside,dis.PolyZkv,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);  
plt.XYZforKv = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.PolyZside,dis.PolyZkv,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZbackKv = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.PolyZside,dis.PolyZkv,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);  
plt.XYZtopKv = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),dis.PolyZkv,'FaceAlpha',1,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZbotKv = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),dis.PolyZkv,'FaceAlpha',1,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);


%% plot polygons for hydraulic head
satColor = [0.1 0.5 1]; % color of "saturated" cells 
satfacealpha = 0.2;
plt.XYZleftH = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.initPscale*dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',initialax,'EdgeAlpha',edgealpha);
plt.XYZrightH = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.initPscale*dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',initialax,'EdgeAlpha',edgealpha);  
plt.XYZforH = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.initPscale*dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',initialax,'EdgeAlpha',edgealpha);
plt.XYZbackH = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.initPscale*dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',initialax,'EdgeAlpha',edgealpha);  
plt.XYZtopH = patch(dis.PolyX,dis.PolyY,dis.initPscale*dis.PolyZ(:,:,1),satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',initialax,'EdgeAlpha',edgealpha);
plt.XYZbotH = patch(dis.PolyX,dis.PolyY,dis.initPscale*dis.PolyZ(:,:,2),satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',initialax,'EdgeAlpha',edgealpha);
plt.XYZtopH2 = patch(dis.PolyX,dis.PolyY,dis.initPscale*dis.PolyZtop(:,:,1),[1 1 1],'FaceAlpha',0.2,'Visible','on','Parent',initialax,'EdgeAlpha',edgealpha);

hold(initialax,'on') % hold axis
% plot potentiometric surface and add legend 
plt.surfH = surf(initialax,dis.X(:,:,1),dis.Y(:,:,1),dis.Hbig,'EdgeAlpha',0.2,'FaceAlpha',0.5);
legend(plt.XYZbotH,'Saturated Thickness','Location','NorthWest')

%% plot polygons for storage terms
SSinit = log(mean(mean(dis.SS)));
plt.XYZleftSS = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.PolyZside,SSinit*dis.PolyZSS,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZrightSS = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.PolyZside,SSinit*dis.PolyZSS,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);  
plt.XYZforSS = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.PolyZside,SSinit*dis.PolyZSS,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZbackSS = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.PolyZside,SSinit*dis.PolyZSS,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);  
plt.XYZtopSS = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),SSinit*dis.PolyZSS,'FaceAlpha',1,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZbotSS = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),SSinit*dis.PolyZSS,'FaceAlpha',1,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);

SYinit = mean(mean(dis.SY));
plt.XYZleftSY = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.PolyZside,SYinit*dis.PolyZSY,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZrightSY = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.PolyZside,SYinit*dis.PolyZSY,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);  
plt.XYZforSY = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.PolyZside,SYinit*dis.PolyZSY,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZbackSY = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.PolyZside,SYinit*dis.PolyZSY,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);  
plt.XYZtopSY = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),SYinit*dis.PolyZSY,'FaceAlpha',1,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZbotSY = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),SYinit*dis.PolyZSY,'FaceAlpha',1,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);

%% plot polygons for porosity 
Pinit = mean(mean(dis.Porosity));
plt.XYZleftP = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.PolyZside,Pinit*dis.PolyZP,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZrightP = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.PolyZside,Pinit*dis.PolyZP,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);  
plt.XYZforP = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.PolyZside,Pinit*dis.PolyZP,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZbackP = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.PolyZside,Pinit*dis.PolyZP,'FaceAlpha',0.7,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);  
plt.XYZtopP = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),Pinit*dis.PolyZP,'FaceAlpha',1,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);
plt.XYZbotP = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),Pinit*dis.PolyZP,'FaceAlpha',1,'Visible','off','Parent',paramsax,'EdgeAlpha',edgealpha);


% set Initial Camera Position in all tabs 
CamPos1 = 1.0e+03*[  2.0812    3.0980    1.8423];
CamPos2 = 1.0e+04*[  0.1639    0.2889    1.7692];
CamPos3 = 1.0e+03*[2.5837    3.3960    0.9113];
set(runMFax,'CameraPosition' , CamPos3,'Visible','on');
set(iboundax,'CameraPosition' , CamPos1,'Visible','on');
set(initialax,'CameraPosition' , CamPos3,'Visible','on');
set(paramsax,'CameraPosition' , CamPos2,'Visible','on');
set(sourceax,'CameraPosition' , CamPos2,'Visible','on');

%% make Climits and colorbars 
cbarVisible = 'off';
cbarPositionIbound = [.22 .78 .45 .035 ];
cbarPosition = [.3 .8 .3 .02 ];
cbarLocation = 'SouthOutside';
cbarFontSize = 8;
cbarLabelFontSize = 12;
cbarAxisLocation = 'in';

plt.KCbar = colorbar(paramsax,'Visible','on','Position',cbarPosition,'Location',cbarLocation,'FontSize',cbarFontSize,'AxisLocation',cbarAxisLocation); 
plt.SSCbar = colorbar(paramsax,'Visible',cbarVisible,'Position',cbarPosition,'Location',cbarLocation,'FontSize',cbarFontSize,'AxisLocation',cbarAxisLocation); 
plt.SYCbar = colorbar(paramsax,'Visible',cbarVisible,'Position',cbarPosition,'Location',cbarLocation,'FontSize',cbarFontSize,'AxisLocation',cbarAxisLocation); 
plt.PCbar = colorbar(paramsax,'Visible',cbarVisible,'Position',cbarPosition,'Location',cbarLocation,'FontSize',cbarFontSize,'AxisLocation',cbarAxisLocation); 
plt.RCHCbar = colorbar(sourceax,'Visible','on','Position',cbarPosition,'Location',cbarLocation,'FontSize',cbarFontSize,'AxisLocation',cbarAxisLocation); 
plt.QCbar = colorbar(sourceax,'Visible',cbarVisible,'Position',cbarPosition,'Location',cbarLocation,'FontSize',cbarFontSize,'AxisLocation',cbarAxisLocation); 
plt.HCbar = colorbar(initialax,'Visible','on','Position',cbarPosition,'Location',cbarLocation,'FontSize',cbarFontSize,'AxisLocation',cbarAxisLocation); 
plt.IboundCbar = colorbar(iboundax,'Ticks',[-0.7 0 0.7],'TickLabels',{'Constant Head','Inactive (No Flow)','Active'},'Visible','on','Position',cbarPositionIbound,'Location',cbarLocation,'FontSize',cbarFontSize);

plt.KCbar.Label.FontSize = cbarLabelFontSize; 
plt.SSCbar.Label.FontSize = cbarLabelFontSize; 
plt.SYCbar.Label.FontSize = cbarLabelFontSize; 
plt.PCbar.Label.FontSize = cbarLabelFontSize; 
plt.IboundCbar.Label.FontSize = cbarLabelFontSize; 
% plt.IboundCbar2.Label.FontSize = cbarLabelFontSize;
plt.RCHCbar.Label.FontSize = cbarLabelFontSize; 
plt.QCbar.Label.FontSize = cbarLabelFontSize;
plt.HCbar.Label.FontSize = cbarLabelFontSize;


%% set colorbar limits
% pumping 
dis.Qmin = 0;
dis.Qmax = 1E7;
dis.Qrng = [0 1E1 1E2 1E3 1E4 1E5 1E6 1E7];
dis.nQvals = 12000;

dis.Qvals = floor(round(logspace(0,7,dis.nQvals-1),3));
dis.Qvals(2:end+1) = dis.Qvals;
dis.Qvals(1)=0;
dis.Qlim = [0  log10(dis.Qmax)];
plt.QCbar.YTick = [0 log10(dis.Qrng(2:end))];
plt.QCbar.YTickLabel = {'0^ ','10^ ','10^2','10^3','10^4','10^5','10^6','10^7'};


%recharge
dis.RCHmin = 0;
dis.RCHmax = .08;
dis.RCHlim = [ dis.RCHmin dis.RCHmax ];
colormap(sourceax,'parula');
caxis(sourceax,dis.RCHlim);

%hydraulic conductivity 
dis.kmin = 1E-5;
dis.kmax = 1E5;
dis.Krng = [ 1E-5 1E-4 1E-3 1E-2 1E-1 1E0 1E1 1E2 1E3 1E4];
dis.nKvals = 12000;
dis.Kvals = round(logspace(-5,5,dis.nKvals),8);
dis.Klim = [ log10(dis.kmin) , log10(dis.kmax)];
colormap(paramsax,summer(dis.nKvals));
caxis(paramsax,dis.Klim);

plt.KCbar.YTick = log10(dis.Krng);
plt.KCbar.YTickLabel = {'10^-^5','10^-^4','10^-^3','10^-^2','10^-^1','1^ ','10^ ','10^2','10^3','10^4'};

% hydraulic head
hmin = min(min(min(dis.H)));
hmax = max(max(max(dis.H)));
dis.Hlim = [ hmin hmax ];
colormap(initialax,'parula');
caxis(initialax,dis.Hlim);

%elevation 
dis.Emin = 0;
dis.Emax = 300;
dis.Elim = [ dis.Emin dis.Emax ];

%specific storage
dis.SSmin = 1E-6;
dis.SSmax = 1E-3;
dis.SSrng = [ 1E-6 1E-5 1E-4 1E-3 ];
dis.SSlim = [ log10(dis.SSmin) log10(dis.SSmax) ];
dis.nSSvals = 4000;
dis.SSvals = round(logspace(-6,-3,dis.nSSvals),8);
plt.SSCbar.YTick = log10(dis.SSrng);
plt.SSCbar.YTickLabel = {'10^-^6','10^-^5','10^-^4','10^-^3'};

%specific yeild
dis.SYmin = 0.1;
dis.SYmax = 0.35;
dis.SYlim = [dis.SYmin  dis.SYmax];

%porosity
dis.Pmin = 0.1;
dis.Pmax = 0.5;
dis.Plim = [ dis.Pmin dis.Pmax ]; 

%ibound
dis.Iboundlim = [-1 1];
colormap(iboundax,[.7 0 1; 0.5 0.5 0.5; 1 1 0]);
caxis(iboundax,dis.Iboundlim);


%% Initalize GUI components
% variables named XXX_edit are uicontrol functions that allow the user to manually type input values -- 'edit' sytle uicontrol 
% variables named XXX_slider are uicontrol functions that allow the user to change values using a slider bar -- 'slider' sytle uicontrol 
% variables named XXX_check are uicontrol functions that allow the user select between 2 model options using a checkbox -- 'checkbox' sytle uicontrol 
% variables named XXX_popup are uicontrol functions that allow the user select between multiple model views (e.g. different parameters) using a popup menu -- 'popup' sytle uicontrol 
% variables named XXX_edit_txt , XXX_slider_txt, XXX_check_txt or XXX_popup_txt are annotations that display the value of their corresponding uicontrol element.

%each uicontrol function is linked to a callback function which are initalized later in the code

% parameters popup
params_popup = uicontrol('Style','popup','Position',[320 770 300 200],'Units','normalized','String',{'Hydraulic Conductivity (K)','Specific Storage (Ss)','Specific Yield (Sy) -- [ Unconfined Only! ]','Porosity (P)'},'Value',1,'Visible','on','Callback',@params_Callback,'ForegroundColor','black','Parent',paramsTab,'FontSize',12,'TooltipString',' Select Parameter to View or Edit');

% hydraulic conductivity (K) 
Kcurr = find(dis.Kvals<=dis.KR(1));%find current value of K to start slider at
dis.Kvals(Kcurr(end))= dis.KR(1);
KR_edit = uicontrol('style','edit','Visible','on','Position',[425 860 80 25],'Units','normalized','String',[num2str(dis.Kvals(Kcurr(end)))],'Parent',paramsTab,'Callback',@Manual_Edit_Callback,'TooltipString','Use Keyboard to Manually Enter Hydraulic Conductivity in Y (E-W) direction ' );
KR_slider = uicontrol('style','slider','Position',[285 830 332 15],'Units','normalized','Min',min(dis.Kvals),'Max',length(dis.Kvals),'Value',Kcurr(end),'SliderStep',[1/(length(dis.Kvals)+1) 1/(length(dis.Kvals)+1)],'Visible','on','Callback',@param_slider_Callback,'Parent',paramsTab,'BusyAction','cancel','TooltipString','Slide to Change Hydraulic Conductivity in Y (E-W) direction ');
KR_slider_txt = annotation(paramsTab,'textbox','Position',[.31 .82 .6 .10],'String',['Hydraulic Conductivity (K_Y)   [ ',num2str(dis.Kvals(Kcurr(end)),'%1.2E'),' m/day ]'],'Visible','on','EdgeColor','none','FontSize',12,'Units','normalized');
KR_colors = summer(dis.nKvals); %colorbar values

Kanis_edit_txt_2 = annotation(paramsTab,'textbox','Position',[.73 .87 .3 .10],'Units','normalized','String',{['K_Y = Hydraulic Conductivity in E-W direction'],['K_X = Hydraulic Conductivity in N-S direction']},'Visible','on','EdgeColor','none','FontSize',9);
Kanis_edit_txt = annotation(paramsTab,'textbox','Position',[.77 .81 .100 .10],'Units','normalized','String',{['Anisotropy Factor'],['     [ K_Y/K_X ]']},'Visible','on','EdgeColor','none','FontSize',10);
Kanis_edit = uicontrol('style','edit','Position',[800 830 40 30],'String','1.00','Units','normalized','Visible','on','Callback',@param_slider_Callback,'Parent',paramsTab,'TooltipString','Use Keyboard to Manually Enter Anisotropy Factor. This is the Ratio of K in the N-S (Y) direction to the E-W (X) direction. ');
kanis_pos = [.78 .77 .04 .04];
Kanis_edit_arrowX = annotation(paramsTab,'arrow',[kanis_pos(1) kanis_pos(1) ] ,[kanis_pos(2) kanis_pos(2)+kanis_pos(3)],'HeadLength',6,'HeadWidth',6,'LineWidth',1.5,'HeadStyle','plain');
Kanis_edit_arrowY = annotation(paramsTab,'arrow',[kanis_pos(1) kanis_pos(1)+kanis_pos(4) ] ,[kanis_pos(2) kanis_pos(2)],'HeadLength',6,'HeadWidth',6,'LineWidth',1.5,'HeadStyle','plain');

KhetLabel_txt = annotation(paramsTab,'textbox','Position',[.095 .83 .6 .10],'Units','normalized','String',['Add Heterogeneity'],'Visible','on','EdgeColor','none','FontSize',12);
Khet1_check = uicontrol('style','checkbox','Position',[170 880 13 12.5],'Units','normalized','Visible','on','Callback',@param_slider_Callback,'Parent',paramsTab,'TooltipString','Add High-K (x10) unit running E-W');
Khet1_txt = annotation(paramsTab,'textbox','Position',[.11 .799 .6 .10],'Units','normalized','String',['Case 1'],'Visible','on','EdgeColor','none','FontSize',9);
Khet2_check = uicontrol('style','checkbox','Position',[170 850 13 12.5],'Units','normalized','Visible','on','Callback',@param_slider_Callback,'Parent',paramsTab,'TooltipString','Add High-K (x10) unit running N-S');
Khet2_txt = annotation(paramsTab,'textbox','Position',[.11 .769 .6 .10],'Units','normalized','String',['Case 2'],'Visible','on','EdgeColor','none','FontSize',9);

% SS
SScurr = find(log10(dis.SSvals)<log10(dis.SSinit)); %find current value of SS to start slider at
dis.SSvals(SScurr(end))= dis.SS(1);
SS_edit = uicontrol('style','edit','Visible','off','Position',[425 860 80 25],'Units','normalized','String',[num2str(dis.SSvals(SScurr(end)))],'Parent',paramsTab,'Callback',@Manual_Edit_Callback,'TooltipString','Use Keyboard to Manually Change Specific Storage.' );

SS_slider = uicontrol('style','slider','Position',[285 830 332 15],'Units','normalized','Min',min(dis.SSvals),'Max',length(dis.SSvals),'Value',SScurr(end),'SliderStep',[1/(length(dis.SSvals)+1) 1/(10)],'Visible','off','Callback',@param_slider_Callback,'Parent',paramsTab,'BusyAction','cancel','TooltipString','Slide to Change Specific Storage.');
SS_slider_txt = annotation(paramsTab,'textbox','Position',[.34 .825 .6 .10],'Units','normalized','String',['Specific Storage    [',num2str(dis.SSvals(SScurr(end)),'%1.2E'),' m^-^1]'],'Visible','off','EdgeColor','none','FontSize',12);
SS_colors = winter(dis.nSSvals);%colorbar values
 
% SY
SYcurr = mean(mean(dis.SY)); %find current value of SS to start slider at
SY_edit = uicontrol('style','edit','Visible','off','Position',[425 860 80 25],'Units','normalized','String',[num2str(SYcurr)],'Parent',paramsTab,'Callback',@Manual_Edit_Callback,'TooltipString','Use Keyboard to Manually Change Specific Yield.' );
SY_slider = uicontrol('style','slider','Position',[285 830 332 15],'Units','normalized','Min',dis.SYmin,'Max',dis.SYmax,'Value',SYcurr,'SliderStep',[1/50 1/20],'Visible','off','Callback',@param_slider_Callback,'Parent',paramsTab,'BusyAction','cancel','TooltipString','Slide to  Change Specific Yield .');
SY_slider_txt = annotation(paramsTab,'textbox','Position',[.34 .825 .6 .10],'Units','normalized','String',['Specific Yeild    [',num2str(SYcurr),'  *100 % ]'],'Visible','off','EdgeColor','none','FontSize',12);

% P
Pcurr = mean(mean(dis.Porosity)); %find current value of SS to start slider at
P_edit = uicontrol('style','edit','Visible','off','Position',[425 860 80 25],'Units','normalized','String',[num2str(Pcurr)],'Parent',paramsTab,'Callback',@Manual_Edit_Callback,'TooltipString','Use Keyboard to Manually Change Porosity.' );
P_slider = uicontrol('style','slider','Position',[285 830 332 15],'Units','normalized','Min',dis.Pmin,'Max',dis.Pmax,'Value',Pcurr,'SliderStep',[1/50 1/20],'Visible','off','Callback',@param_slider_Callback,'Parent',paramsTab,'BusyAction','cancel','TooltipString','Slide to Change Porosity.');
P_slider_txt = annotation(paramsTab,'textbox','Position',[.34 .825 .6 .10],'Units','normalized','String',['Porosity    [',num2str(Pcurr),' *100 % ]'],'Visible','off','EdgeColor','none','FontSize',12);

% sources ( Q, RCH)
source_popup = uicontrol('Style','popup','Position',[320 750 300 200],'Units','normalized','String',{'Recharge (RCH) ','Pumping (Q)'},'Value',1,'Visible','on','Callback',@source_Callback,'ForegroundColor','black','Parent',sourceTab,'FontSize',12);

% RCH
RCHcurr = mean(mean(dis.RCH)); %find current value of K to start slider at
RCH_edit = uicontrol('style','edit','Visible','on','Position',[425 860 80 25],'Units','normalized','String',[num2str(RCHcurr)],'Parent',sourceTab,'Callback',@Manual_Edit_Callback,'TooltipString','Use Keyboard to Manually Change Surface Recharge.' );

rch_slider = uicontrol('style','slider','Position',[285 830 332 15],'Units','normalized','Min',dis.RCHmin,'Max',dis.RCHmax,'Value',RCHcurr,'SliderStep',[.01 .005],'Visible','on','Callback',@source_slider_Callback,'Parent',sourceTab,'BusyAction','cancel','TooltipString','Slide to Change Surface Recharge.' );
rch_slider_txt = annotation(sourceTab,'textbox','Position',[.34 .82 .6 .10],'String',['Surface Recharge    [',num2str(round(RCHcurr,5)),'  m/day ]'],'Visible','on','EdgeColor','none','FontSize',12,'Units','normalized');

% Q
Qcurr = find(dis.Qvals<-dis.q);
Q_edit = uicontrol('style','edit','Visible','off','Position',[425 860 80 25],'Units','normalized','String',[num2str(-dis.q)],'Parent',sourceTab,'Callback',@Manual_Edit_Callback,'TooltipString','Use Keyboard to Manually Change Pumping Discharge Rate.' );
Q_slider = uicontrol('style','slider','Position',[285 830 332 15],'Units','normalized','Min',0,'Max',dis.nQvals,'Value',Qcurr(end),'SliderStep',[1/length(dis.Qvals) 1/20],'Visible','off','Callback',@source_slider_Callback,'Parent',sourceTab,'BusyAction','cancel','TooltipString','Slide to Change Pumping Discharge Rate.');
Q_slider_txt = annotation(sourceTab,'textbox','Position',[.30 .82 .6 .10],'String',['Discharge from Pumping     ['  ,num2str(dis.q,'%1.2E'),'   m^3/day ]'],'Visible','off','EdgeColor','none','FontSize',12,'Units','normalized');

% initial Conditions (Head (H) , Layer thickness (ELEV), Layer type (CNF,UNCNF))
% H
H_slider_txt = annotation(initialTab,'textbox','Position',[.34 .76 .6 .10],'String',['Initial Hydraulic Head  [m/day]'],'Visible','on','EdgeColor','none','FontSize',12,'Units','normalized');

% ELEV
ELEVcurr = dis.LzTop;
ELEV_edit = uicontrol('style','edit','Visible','on','Position',[425 925 40 25],'Units','normalized','String',[num2str(ELEVcurr)],'Parent',initialTab,'Callback',@Manual_Edit_Callback,'TooltipString','Use Keyboard to Manually Change Top Elevation of Aquifer ' );
ELEV_slider = uicontrol('style','slider','Position',[285 900 332 15],'Units','normalized','Min',10,'Max',dis.Elim(2),'Value',ELEVcurr,'SliderStep',[1/dis.LzTop 1/10],'Visible','on','Callback',@initial_slider_Callback,'Parent',initialTab,'BusyAction','cancel','TooltipString','Slide to Change Top Elevation of Aquifer');
ELEV_slider_txt = annotation(initialTab,'textbox','Position',[.33 .88 .6 .10],'Units','normalized','String',['Elevation at Top of Aquifer  [' num2str(ELEVcurr),' m ]'],'Visible','on','EdgeColor','none','FontSize',12);



% annotations on the Initial Conditions Tab 
IC_text_str = {'Note: This is only an initial guess at the MODFLOW solution for the first timestep.';' '; 'This hydraulic head distribution is not physically plausible! ';' ' ;'For this reason, a steady-state solution is obtained and is used as the initial guess for the first transient timestep. ' };
IC_text_str = {'Here, define the elevation of the top of the aquifer.';'';'If the top is above the constant head boundaries defined by MODFLOW initial hydraulic heads, the aquifer will be unconfined.';' ';'If the top is below the constant head boundaries, the aquifer will be confined.';' ' ; };
IC_text = annotation(initialTab,'textbox','Position',[.05 .88 .2 .1],'String',IC_text_str,'Visible','on','FontSize',10,'EdgeColor','none','Units','normalized');

confined_note_str = {'For the purposes of this demonstation, the initial hydraulic head distribution cannot be changed.';' '; 'Confined conditions imply that the cell saturated thickness remains unchanged throughout the simulation. Hydraulic heads can (unrealistically) be calculated as less that than the bottom elevation of the aquifer.';' ';'In unconfined conditions, the thickness of the aquifer is calculated as the hydraulic heads at the current step minus the bottom elevation of the aquifer. The aquifer is said to be "de-watered" if hydraulic heads decline to the bottom of the aquifer.';};
confined_note = annotation(initialTab,'textbox','Position',[.65 .78 .3 .2],'Units','normalized','String',confined_note_str,'Visible','on','EdgeColor','none','FontSize',9);

% checkbox displaying whether aquifer is confined or unconfined
confined_check = uicontrol('style','checkbox','Position',[800 650 15 15],'Units','normalized','Value',1,'Callback',@initial_slider_Callback,'Parent',initialTab,'Visible','off','TooltipString','Confined (unchecked) or Unconfined . See note above');
confined_check_txt = annotation(initialTab,'textbox','Position',[.68 .59 .100 .10],'Units','normalized','String',[' Aquifer is \bf \it {Unconfined}'],'Visible','on','EdgeColor','none','FontSize',12);

% edit boxes for time discretization & execute Modflow/Modpath
nper_edit = uicontrol('style','edit','Position',[160 930 50 20],'Units','normalized','String',num2str(dis.nper),'Visible','on','Callback',@MFdis_Callback,'Enable','on','Parent',runMFTab,'TooltipString','Use Keyboard to Change the Number of Stress Periods in the Simulation');
nper_edit_txt = annotation(runMFTab,'textbox','Position',[.215 .8525 .100 .10],'Units','normalized','String','# Stress Periods ','Visible','on','EdgeColor','none');

% period length 
perlen_edit = uicontrol('style','edit','Position',[160 890 50 20],'Units','normalized','String',num2str(dis.perlen),'Visible','on','Callback',@MFdis_Callback,'enable','on','Parent',runMFTab,'TooltipString','Use Keyboard to Change the Length (in days) of Each Stress Period');
perlen_edit_txt = annotation(runMFTab,'textbox','Position',[.215 .8125 .100 .10],'Units','normalized','String',['Stress Period Length (days) '],'Visible','on','EdgeColor','none');

% final time 
tf_edit = uicontrol('style','edit','Position',[160 850 50 20],'Units','normalized','String',num2str(str2num(perlen_edit.String)*str2num(nper_edit.String)),'Visible','on','Enable','off','Callback',@MFdis_Callback,'Parent',runMFTab,'TooltipString','Total Simulated Time = # Stress Periods * Stress Period Length');
tf_edit_txt = annotation(runMFTab,'textbox','Position',[.215 .7725 .100 .10],'Units','normalized','String',['Total Time (days) '],'Visible','on','EdgeColor','none');
scl = .995;

% checkbox to display location of tracer particles
particle_check = uicontrol('style','checkbox','Position',[580 890 15 15],'Value',0,'Callback',@PreRunCheck_Callback,'Parent',runMFTab,'Visible','on','Units','normalized');
particle_check_txt = annotation(runMFTab,'textbox','Position',[.6 scl*.8152 .100 .10],'Units','normalized','String',['Show Particle Initial Positions'],'Visible','on','EdgeColor','none','FontSize',10);

% checkbox to display location of well and pumping rate
well_check = uicontrol('style','checkbox','Position',[580 910 15 15],'Value',0,'Callback',@PreRunCheck_Callback,'Parent',runMFTab,'Visible','on','Units','normalized');
well_check_txt = annotation(runMFTab,'textbox','Position',[.6 scl*.8341 .100 .10],'Units','normalized','String',['Show Pumping Well'],'Visible','on','EdgeColor','none','FontSize',10);

% checkbox to display boundary conditions
BC_check = uicontrol('style','checkbox','Position',[580 930 15 15],'Value',0,'Callback',@PreRunCheck_Callback,'Parent',runMFTab,'Visible','on','Units','normalized');
BC_check_txt = annotation(runMFTab,'textbox','Position',[.6 scl*.8534 .100 .10],'Units','normalized','String',['Show Boundary Conditions'],'Visible','on','EdgeColor','none','FontSize',10);

% run modflow button (executes modflow and modpath models)
runMF_but = uicontrol('style','pushbutton','Position',[550 800 140 40],'Units','normalized','String',{' MODFLOW 2005 / MODPATH 7 '},'Visible','on','Callback',@runMF_Callback,'Parent',runMFTab,'TooltipString','Press to Initiate MODFLOW 2005 and MODPATH 7');

% Reset to Defaults Button 
reset_but = uicontrol('style','pushbutton','Position',[700 800 100 40],'Units','normalized','String',{'Reset to Defaults'},'Visible','on','Callback',@reset_but_Callback,'Parent',runMFTab,'TooltipString','Press to Reset ALL values to defaults');

%% Initalize Modpath Particle Initial Positions 
dis.pxA = dis.Lx/4; %xpos cent
dis.pyA = 3*dis.Ly/4 ; %ypos cent
dis.prA = 20;  %radius
dis.pzA = dis.LzTop/2;  %depth

dis.pxB = dis.Lx/4; %xpos cent
dis.pyB = dis.Ly/4; %ypos cent
dis.prB = 20;  %radius
dis.pzB = dis.LzTop/2;  %depth

dis.pxC = dis.Lx/5; %xpos cent
dis.pyC = dis.Ly/2; %ypos cent
dis.prC = 30;  %radius
dis.pzC = dis.LzTop/2;  %depth


MPin.ParticleCountA = 10;
MPin.ParticleCountB = 10;
MPin.ParticleCountC = 15;

MPin.ParticleCount = MPin.ParticleCountA + MPin.ParticleCountB + MPin.ParticleCountC;


dis.randthA = 2*pi*rand(1,MPin.ParticleCountA);
dis.thA = linspace(0,2*pi,MPin.ParticleCountA);

dis.xunitA = dis.prA*(rand(1,MPin.ParticleCountA).^0.5) .* cos(dis.randthA) + dis.pxA;
dis.yunitA = dis.prA*(rand(1,MPin.ParticleCountA).^0.5) .* sin(dis.randthA) + dis.pyA;
dis.zunitA = dis.pzA*ones(size(dis.randthA));


dis.randthB = 2*pi*rand(1,MPin.ParticleCountB);
dis.thA = linspace(0,2*pi,MPin.ParticleCountB);

dis.xunitB = dis.prB*(rand(1,MPin.ParticleCountB).^0.5) .* cos(dis.randthB) + dis.pxB;
dis.yunitB = dis.prB*(rand(1,MPin.ParticleCountB).^0.5) .* sin(dis.randthB) + dis.pyB;
dis.zunitB = dis.pzB*ones(size(dis.randthB));

dis.randthC = 2*pi*rand(1,MPin.ParticleCountC);
dis.thC = linspace(0,2*pi,MPin.ParticleCountC);

dis.xunitC = dis.prC*(rand(1,MPin.ParticleCountC).^0.5) .* cos(dis.randthC) + dis.pxC;
dis.yunitC = dis.prC*(rand(1,MPin.ParticleCountC).^0.5) .* sin(dis.randthC) + dis.pyC;
dis.zunitC = dis.pzC*ones(size(dis.randthC));

dis.PcolorA = [1 0.4 0.6];
dis.PcolorB = [0.423 0.976 .223];
dis.PcolorC = [0.101 1 0.98];
dis.Psize = 12;
dis.PLegendText = {['Particle Group A  (',num2str(MPin.ParticleCountA),')'],['Particle Group B  (',num2str(MPin.ParticleCountB),')'],['Particle Group C  (',num2str(MPin.ParticleCountC),')']};
% hold(runMFax,'on')
% plt.ParticlePos = scatter3('Parent',runMFax,dis.xunit,dis.Ly-dis.yunit,dis.zunit,'filled','Visible','off');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% Callback functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%each uicontrol function from the previous section is linked to a callback function 
reset_but_Callback % reset everything -- not sure why but it wont work otherwise :)  

%% Manual Edit button callbacks (get values from 'edit' uicontrols)
function Manual_Edit_Callback(source,events)
%% Callback function for edit checkboxes 
% when parameter values are updated in edit or slider uicontrols this funciton updates
% the corresponding information in the dis structure (which contains the model input data) 

% for each parameter, the current value of the slider/edit uicontrol read,
% the new value is redrawn an and the value stored in the dis structure

% if the value in an 'edit; uicontrol is empty, the corresponding value in
% the dis structure is superimposed

% if the input value on any slider or edit uidcontrol exceeds the tolerated
% limits, then the parameters respective lower/upper allowed value is used

% ELEV
currELEV = str2num(ELEV_edit.String)
if currELEV > dis.Emax
    currELEV = dis.Emax;
elseif currELEV < dis.Emin
    currELEV = dis.Emin;
end
ELEV_edit.String = num2str(currELEV);
ELEV_slider.Value = currELEV;

% Q 
currQ = str2num(Q_edit.String);
if isempty(currQ) == 1 % check if edit box is empty 
    currQ = dis.Qvals(ceil(Q_slider.Value));
    Q_edit.String = num2str(currQ);
end
% check if param value is within tolerated limits 
if currQ > dis.Qmax
    currQ = dis.Qmax;
elseif currQ < dis.Qmin
    currQ = dis.Qmin;
end
Q_slider_temp = find(dis.Qvals>=currQ);
dis.Qvals(Q_slider_temp(1)) = currQ;
Q_edit.String = num2str(currQ);
Q_slider.Value = Q_slider_temp(1);

% RCH 
currRCH = str2num(RCH_edit.String);
if isempty(currRCH) == 1% check if edit box is empty
    currRCH = ceil(RCH_slider.Value);
    RCH_edit.String = num2str(currRCH);
end
% check if param value is within tolerated limits 
if currRCH > dis.RCHmax
    currRCH = dis.RCHmax;
elseif currRCH < dis.RCHmin
    currRCH = dis.RCHmin;
end
RCH_edit.String = num2str(currRCH);
rch_slider.Value = currRCH;

% K 
currK = str2num(KR_edit.String);
if isempty(currK) == 1% check if edit box is empty
    currK = dis.Kvals(ceil(KR_slider.Value));
    KR_edit.String = num2str(currK);
end
% check if param value is within tolerated limits 
if currK > dis.kmax
    currK = dis.kmax;
elseif currK < dis.kmin
    currK = dis.kmin;
end
KR_slider_temp = find(dis.Kvals<=currK);
dis.Kvals(KR_slider_temp(end)) = currK;
KR_edit.String = num2str(currK);
KR_slider.Value = KR_slider_temp(end);

% SS 
currSS = str2num(SS_edit.String);
if isempty(currSS) == 1% check if edit box is empty
    currSS = dis.SSvals(ceil(SS_slider.Value));
   SS_edit.String = num2str(currSS);
end
% check if param value is within tolerated limits 
if currSS > dis.SSmax
    currSS = dis.SSmax;
elseif currSS < dis.SSmin
    currSS = dis.SSmin;
end
SS_slider_temp = find(dis.SSvals<=currSS);
dis.SSvals(SS_slider_temp(end)) = currSS;
SS_edit.String = num2str(currSS);
SS_slider.Value = SS_slider_temp(end);

% SY 
currSY = str2num(SY_edit.String);
if isempty(currSY) == 1% check if edit box is empty
    currSY = ceil(SS_slider.Value);
    SS_edit.String = num2str(currSS);
end


% Porosity
currP = str2num(P_edit.String);
if isempty(currP) == 1% check if edit box is empty
    currP = ceil(P_slider.Value);
    P_edit.String = num2str(currP);
end
% check if param value is within tolerated limits 
if currP > dis.Pmax
    currP = dis.Pmax;    
elseif currP < dis.Pmin
    currP = dis.Pmin;
end
P_edit.String = num2str(currP);
P_slider.Value = currP;

% check if param value is within tolerated limits 
error =0
if currSY > dis.SYmax
    currSY = dis.SYmax;
elseif currSY < dis.SYmin
    currSY = dis.SYmin;
elseif currSY> currP
    %msgbox_SY = errordlg('Specific yeild must be less than or equal to porosity','Invalid Value')
    error = 1
    currSY = dis.Pinit
end


SY_edit.String = num2str(currSY);
SY_slider.Value = currSY;

%callback corresponding sliders
param_slider_Callback;
initial_slider_Callback;
source_slider_Callback;

if error ==1 
    msgbox_SY = errordlg('Specific yeild must be less than or equal to porosity. Setting specific yeild equal to porosity','Invalid Value')
    error = 0
end 

end
%% PARAM SLIDER CALLBACK (get values from 'slider' uicontrols for parameters K,SS,SY,porosity)
function param_slider_Callback(source,events)
 %% callback function for parameter  uicontrols (K,SS,SY,porosity)
 % updates the color of the polygons for each parameter based on thei value
 % of the slider or edit box
 
%get base K matrix to use for scaling in anisotorpy and adding heterogeneity
if Khet1_check.Value ==1 && Khet2_check.Value == 0
    Kbase = dis.KHET1;
    KPolyColor = dis.PolyZkhet1;
    dis.PolyZkhet1;
elseif Khet1_check.Value ==0 && Khet2_check.Value ==1
    Kbase = dis.KHET2;
    KPolyColor = dis.PolyZkhet2;
    
elseif Khet1_check.Value ==1 && Khet2_check.Value ==1
    Kbase = dis.KHET12;
    KPolyColor = dis.PolyZkhet12;
    
elseif Khet1_check.Value ==0 && Khet2_check.Value ==0
    Kbase = dis.KRbase;
    KPolyColor = dis.PolyZkr;
    
end

% Update K for added  anisotory and heterogeneity 

%make sure K is in range 
KcurrMax = find(dis.Kvals<=1E4);
KcurrMin = find(dis.Kvals>=1E-7);

KRscale = ceil(KR_slider.Value);

if dis.Kvals(KRscale) >= 1E-7 && dis.Kvals(KRscale)<=1E4
   elseif dis.Kvals(KRscale) < 1E-7
    KRscale = KcurrMin(1);
   elseif dis.Kvals(KRscale) > 1E4
    KRscale = KcurrMax(end);
end

Kval =  dis.Kvals(KRscale);

 KR_edit.String = num2str(Kval);

 KR_slider_txt.String = ['Hydraulic Conductivity    [',num2str(Kval,'%1.2E'),' m/day ]'];
KPolyColor = log10(Kval*KPolyColor);

plt.XYZleftKr.CData = KPolyColor;
plt.XYZrightKr.CData = KPolyColor;
plt.XYZforKr.CData = KPolyColor;
plt.XYZbackKr.CData = KPolyColor;
plt.XYZtopKr.CData = KPolyColor;
plt.XYZbotKr.CData = KPolyColor;

%update anisotropy factor
AnisFactor = abs(str2num(Kanis_edit.String));
Kanis_edit.String = num2str(AnisFactor);
if AnisFactor < 1    
       Kanis_edit_arrowX.X = [kanis_pos(1) kanis_pos(1) ];
       Kanis_edit_arrowX.Y = [kanis_pos(2) kanis_pos(2)+(1/AnisFactor)*kanis_pos(3)];
     
       Kanis_edit_arrowY.X = [kanis_pos(1) kanis_pos(1)+kanis_pos(4) ]; 
       Kanis_edit_arrowY.Y = [kanis_pos(2) kanis_pos(2)]; 
      
       dis.KC = ((dis.Kvals(KRscale)*Kbase));    
       dis.KR = ((1/AnisFactor)*(dis.Kvals(KRscale)*Kbase));
elseif AnisFactor > 1  
    
       Kanis_edit_arrowX.X = [kanis_pos(1) kanis_pos(1)];
       Kanis_edit_arrowX.Y = [kanis_pos(2) kanis_pos(2)+kanis_pos(3)] ; 
        
       Kanis_edit_arrowY.X = [kanis_pos(1) kanis_pos(1)+(AnisFactor)*kanis_pos(3) ]; 
       Kanis_edit_arrowY.Y = [kanis_pos(2) kanis_pos(2)];
       

       dis.KC = ((AnisFactor)*(dis.Kvals(KRscale)*Kbase));
       dis.KR = ((dis.Kvals(KRscale)*Kbase));
else 
    
Kanis_edit_arrowX.X = [kanis_pos(1) kanis_pos(1) ];
Kanis_edit_arrowX.Y = [kanis_pos(2) kanis_pos(2)+kanis_pos(3)] ; 

Kanis_edit_arrowY.X = [kanis_pos(1) kanis_pos(1)+kanis_pos(4) ]; 
Kanis_edit_arrowY.Y = [kanis_pos(2) kanis_pos(2)];  

dis.KR = (dis.Kvals(KRscale)*Kbase);
dis.KC = (dis.Kvals(KRscale)*Kbase);

end

% update base SS  
SSscale = ceil(SS_slider.Value);
SS_edit.String = num2str(dis.SSvals(SSscale));

SSval =  log10(dis.SSvals(SSscale));


plt.XYZleftSS.CData = SSval*dis.PolyZSS;
plt.XYZrightSS.CData = SSval*dis.PolyZSS;
plt.XYZforSS.CData = SSval*dis.PolyZSS;
plt.XYZbackSS.CData = SSval*dis.PolyZSS;
plt.XYZtopSS.CData = SSval*dis.PolyZSS;
plt.XYZbotSS.CData = SSval*dis.PolyZSS;

dis.SS=dis.SSvals(SSscale)*dis.SSbase;



% update porosity 
Pval = round(P_slider.Value,2);
P_edit.String = num2str(Pval);
plt.XYZleftP.CData = Pval*dis.PolyZP;
plt.XYZrightP.CData = Pval*dis.PolyZP;
plt.XYZforP.CData = Pval*dis.PolyZP;
plt.XYZbackP.CData = Pval*dis.PolyZP;
plt.XYZtopP.CData = Pval*dis.PolyZP;
plt.XYZbotP.CData = Pval*dis.PolyZP;

dis.Porosity=Pval*dis.PorosityBase;

SYval = round(SY_slider.Value,2);

error = 0
if SYval> Pval
    currSY = dis.SYinit
    %msgbox_SY = errordlg('Specific yeild must be less than or equal to porosity','Invalid Value')
    error = 1
end
% update base sy
if error ==1
   SYval = Pval
   SY_slider.Value = Pval
else
   SYval = round(SY_slider.Value,2);
end

SY_edit.String = num2str(SYval);
plt.XYZleftSY.CData = SYval*dis.PolyZSY;
plt.XYZrightSY.CData = SYval*dis.PolyZSY;
plt.XYZforSY.CData = SYval*dis.PolyZSY;
plt.XYZbackSY.CData = SYval*dis.PolyZSY;
plt.XYZtopSY.CData = SYval*dis.PolyZSY;
plt.XYZbotSY.CData = SYval*dis.PolyZSY;
dis.SY=SYval*dis.SYbase;  

if error ==1 
    msgbox_SY = errordlg('Specific yeild must be less than or equal to porosity. Setting specific yeild equal to porosity','Invalid Value')
    error = 0
end 

%% update slider texts

P_slider_txt.String = ['Porosity    [',num2str(Pval),' *100 % ]'];
SY_slider_txt.String = ['Specific Yeild    [',num2str(SYval),'  *100 % ]'];
SS_slider_txt.String = ['Specific Storage    [ ',num2str(dis.SSvals(SSscale),'%1.2E'),' m^-^1 ]'];

end
%% SOURCE SLIDER CALLBACK (get values from 'slider' uicontrols for parameters RCH,Q)
function source_slider_Callback(source, events)
%% callback function for source  uicontrols (RCH,Q)
% updates the color of the polygons for each parameter based on thei value
% of the slider or edit box
RCHval = round(rch_slider.Value,3);
Qval = floor(Q_slider.Value)+1;


RCH_edit.String = num2str(RCHval);

plt.XYZleftRCH.CData = RCHval+dis.PolyZrch;
plt.XYZrightRCH.CData = RCHval+dis.PolyZrch;
plt.XYZforRCH.CData = RCHval+dis.PolyZrch;
plt.XYZbackRCH.CData = RCHval+dis.PolyZrch;
plt.XYZtopRCH.CData = RCHval+dis.PolyZrch;
plt.XYZbotRCH.CData = RCHval+dis.PolyZrch;

if  Qval<=length(dis.Qvals)
    Q_edit.String = num2str(dis.Qvals(Qval-1));
if Qval==1
    Qscale = 0;
    plt.XYZleftQ.CData = 0*dis.PolyZQ;
    plt.XYZrightQ.CData = 0*dis.PolyZQ;
    plt.XYZforQ.CData = 0*dis.PolyZQ;
    plt.XYZbackQ.CData = 0*dis.PolyZQ;
    plt.XYZtopQ.CData = 0*dis.PolyZQ;
    plt.XYZbotQ.CData = 0*dis.PolyZQ; 
else
    Qscale = log10(dis.Qvals(Qval));
    
    QpolyColor = dis.PolyZQ ;
    QpolyColor(:,dis.Qind) = Qscale;
    
    
    
    plt.XYZleftQ.CData = QpolyColor;
    plt.XYZrightQ.CData = QpolyColor;
    plt.XYZforQ.CData = QpolyColor;
    plt.XYZbackQ.CData = QpolyColor;
    plt.XYZtopQ.CData = QpolyColor;
    plt.XYZbotQ.CData = QpolyColor;
end
else 
    Q_edit.String = num2str(dis.Qvals(end));
    Qscale = log10(dis.Qvals(end));  
    QpolyColor = dis.PolyZQ ;
    QpolyColor(:,dis.Qind) = Qscale;
    
    plt.XYZleftQ.CData = QpolyColor;
    plt.XYZrightQ.CData = QpolyColor;
    plt.XYZforQ.CData = QpolyColor;
    plt.XYZbackQ.CData = QpolyColor;
    plt.XYZtopQ.CData = QpolyColor;
    plt.XYZbotQ.CData = QpolyColor;   
   
end
dis.RCH = RCHval+dis.RCHbase;


if Qscale ~= 0
dis.q = -(10^Qscale);
else
 dis.q =0 ;
end

Q_slider_txt.String = ['Discharge from Pumping     ['  ,num2str(dis.q,'%1.2E'),'   m^3/day ]'];
rch_slider_txt.String = ['Surface Recharge    [',num2str(round(mean(mean(mean(dis.RCH))),4)),'  m/day ]'];

PreRunCheck_Callback
end
%% PRE RUN CHECK CALLBACK (update visuals on runMF tab) 
function PreRunCheck_Callback(source,events)
%this callback function updates visuals on the runMF tab (time discretization and general model info)  the if statements below cycle through all possible checkbox combinations
% (e.g show well pumping, show particle initial positions, show boundary conditions) and draws the appropriate information on the axis

       % get values of each checckbox 
        BCcheck_val = BC_check.Value;
        Pcheck_val = particle_check.Value;
        Wcheck_val = well_check.Value;
        check_vals = [BCcheck_val Wcheck_val Pcheck_val];
        
        % set current axis
        axes(runMFax)
        cla(runMFax)
        
        % format axis
        legend('off')
        LegendLoc = 'NorthWest';
        Zextra = log10(dis.Qmax);
        Qscaled = log10(abs(dis.q))/log10(dis.Qmax);
        qfmtspec = '%1.2E';
        facealpha1 = 0.1;
        set(runMFax,'ZLim',get(initialax,'ZLim'),'ZTick',get(initialax,'ZTick'),'ZTickLabel',get(initialax,'ZTickLabel'),'PlotBoxAspectRatio',[dis.LxNrm dis.LyNrm 0.6]);
        zlabel(initialax,'Z_d_i_s_t (m)');
        dis.Iboundlim = [-1 1]; %limits on boundary conditions colorbar
        colormap(runMFax,[.7 0 1; 0.5 0.5 0.5; 1 1 0]);
        caxis(runMFax,dis.Iboundlim);

        satColor = [0.1 0.5 1];
        satfacealpha = 0.1;
        sidefacealpha = 0.1;
        sideedgealpha = 0.1;
        edgealpha = 0.1;
        
        
          colors = zeros(size(dis.X(:,:,1)))
          plt.surfHrunMF = surf(runMFax,dis.X(:,:,1),dis.Y(:,:,1),dis.Hbig,colors,'EdgeAlpha',0.2,'FaceAlpha',0.2,'Visible','on');
          plt.surfHrun.Cdata = colors

        if check_vals == [0 0 0] %none
            
            plt.XYZleft = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',sideedgealpha);
            plt.XYZright = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',sideedgealpha);  
            plt.XYZfor = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',sideedgealpha);
            plt.XYZback = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',sideedgealpha);  
            plt.XYZtop = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),satfacealpha,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZtop2 = patch(dis.PolyX,dis.PolyY,dis.PolyZtop,[1 1 1],'FaceAlpha',facealpha1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);            
            plt.XYZbot = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),satfacealpha,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha); 
            
            prepos = get(gca,'Position'); %workaround for legend auto changing axis position            
            legend([plt.XYZleft],{'Saturated Thickness'},'Location',LegendLoc)
            set(gca,'Position',prepos);
            
        elseif check_vals == [1 0 0]  % boundary conditions only
          
            plt.XYZleft = patch(dis.PolyXsideL(:,[1:dis.ncol:dis.nrow*dis.ncol]),dis.PolyYsideLR(:,[1:dis.ncol:dis.nrow*dis.ncol]),dis.PolyZside(:,[1:dis.ncol:dis.nrow*dis.ncol]),[.7 0 1],'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZright = patch(dis.PolyXsideR(:,[end:-dis.ncol:1]),dis.PolyYsideLR(:,[end:-dis.ncol:1]),dis.PolyZside(:,[end:-dis.ncol:1]),[.7 0 1],'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZfor = patch(dis.PolyXsideFB(:,[1:dis.ncol]),dis.PolyYsideF(:,[1:dis.ncol]),dis.PolyZside(:,[1:dis.ncol]),edgeindexFB,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZback = patch(dis.PolyXsideFB(:,[end-dis.ncol+1:end]),dis.PolyYsideB(:,[end-dis.ncol+1:end]),dis.PolyZside(:,[end-dis.ncol+1:end]),edgeindexFB,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZtop = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),dis.PolyZibound,'FaceAlpha',1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZbot = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),dis.PolyZibound,'FaceAlpha',1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZtop2 = patch(dis.PolyX,dis.PolyY,dis.PolyZtop,[1 1 1],'FaceAlpha',facealpha1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);

 
        elseif check_vals == [0 1 0] %well only
            
            plt.XYZleft = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZright = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZfor = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZback = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZtop = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZbot = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha); 
            plt.XYZtop2 = patch(dis.PolyX,dis.PolyY,dis.PolyZtop,[1 1 1],'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            
            hold(runMFax,'on')

            plt.WellPosLine = plot3(runMFax,[dis.xposCent(dis.Qcol) dis.xposCent(dis.Qcol)],[dis.yposCent(dis.Qrow) dis.yposCent(dis.Qrow)],[dis.LzBot,dis.LzTop+Qscaled*Zextra],'Color',[1 0.2 0.2],'LineWidth',3);
            plt.WellPosDot = scatter3(runMFax,[dis.xposCent(dis.Qcol) ],[dis.yposCent(dis.Qrow) ],[dis.LzTop+Qscaled*Zextra],100,[1 0.2 0.2],'filled','MarkerEdgeColor','Black','LineWidth',1.3);
            text(dis.xposCent(dis.Qcol), dis.yposCent(dis.Qrow) ,1.1*(dis.LzTop+Qscaled*Zextra),[ num2str(dis.q,qfmtspec), '  m^3 day^-^1'])
            text(dis.xposCent(dis.Qcol), dis.yposCent(dis.Qrow) ,1.2*(dis.LzTop+Qscaled*Zextra),[ 'Well Discharge Rate: '])
 
            prepos = get(gca,'Position'); %workaround for legend auto changing axis position            
            legend([plt.XYZleft],{'Saturated Thickness'},'Location',LegendLoc)
            set(gca,'Position',prepos);
            
        elseif check_vals == [0 0 1] %particles only
            
            plt.XYZleft = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZright = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZfor = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZback = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZtop = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZbot = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha); 
            plt.XYZtop2 = patch(dis.PolyX,dis.PolyY,dis.PolyZtop,satColor,'FaceAlpha',facealpha1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);

            hold(runMFax,'on')
            plt.ParticlePosA = scatter3('Parent',runMFax,dis.xunitA,dis.Ly-dis.yunitA,1.01*dis.zunitA,dis.Psize,dis.PcolorA ,'filled','Visible','on');
            plt.ParticlePosB = scatter3('Parent',runMFax,dis.xunitB,dis.Ly-dis.yunitB,1.01*dis.zunitB,dis.Psize,dis.PcolorB,'filled','Visible','on'); 
            plt.ParticlePosC = scatter3('Parent',runMFax,dis.xunitC,dis.Ly-dis.yunitC,1.01*dis.zunitC,dis.Psize,dis.PcolorC,'filled','Visible','on'); 
            prepos = get(gca,'Position'); %workaround for legend auto changing axis position            
            legend([plt.XYZleft plt.ParticlePosA,plt.ParticlePosB,plt.ParticlePosC],['Saturated Thickness',dis.PLegendText],'Location',LegendLoc)
            set(gca,'Position',prepos);
            
        elseif check_vals == [1 1 0] %boundary conditions and wells
            plt.XYZleft = patch(dis.PolyXsideL(:,[1:dis.ncol:dis.nrow*dis.ncol]),dis.PolyYsideLR(:,[1:dis.ncol:dis.nrow*dis.ncol]),dis.PolyZside(:,[1:dis.ncol:dis.nrow*dis.ncol]),-1,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZright = patch(dis.PolyXsideR(:,[end:-dis.ncol:1]),dis.PolyYsideLR(:,[end:-dis.ncol:1]),dis.PolyZside(:,[end:-dis.ncol:1]),-1,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZfor = patch(dis.PolyXsideFB(:,[1:dis.ncol]),dis.PolyYsideF(:,[1:dis.ncol]),dis.PolyZside(:,[1:dis.ncol]),edgeindexFB,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZback = patch(dis.PolyXsideFB(:,[end-dis.ncol+1:end]),dis.PolyYsideB(:,[end-dis.ncol+1:end]),dis.PolyZside(:,[end-dis.ncol+1:end]),edgeindexFB,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZtop = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),dis.PolyZibound,'FaceAlpha',1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZbot = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),dis.PolyZibound,'FaceAlpha',1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZtop2 = patch(dis.PolyX,dis.PolyY,dis.PolyZtop,[1 1 1],'FaceAlpha',facealpha1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);

            hold(runMFax,'on')
            plt.WellPosLine = plot3(runMFax,[dis.xposCent(dis.Qcol) dis.xposCent(dis.Qcol)],[dis.yposCent(dis.Qrow) dis.yposCent(dis.Qrow)],[dis.LzBot,dis.LzTop+Qscaled*Zextra],'Color',[1 0.2 0.2],'LineWidth',3);
            plt.WellPosDot = scatter3(runMFax,[dis.xposCent(dis.Qcol) ],[dis.yposCent(dis.Qrow) ],[dis.LzTop+Qscaled*Zextra],100,[1 0.2 0.2],'filled','MarkerEdgeColor','Black','LineWidth',1.3);
            text(dis.xposCent(dis.Qcol), dis.yposCent(dis.Qrow) ,1.1*(dis.LzTop+Qscaled*Zextra),[ num2str(dis.q,qfmtspec), '  m^3 day^-^1'])
            text(dis.xposCent(dis.Qcol), dis.yposCent(dis.Qrow) ,1.2*(dis.LzTop+Qscaled*Zextra),[ 'Well Discharge Rate: '])
 
           
            
        elseif check_vals == [0 1 1] % well and particle
            
            plt.XYZleft = patch(dis.PolyXsideL,dis.PolyYsideLR,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZright = patch(dis.PolyXsideR,dis.PolyYsideLR,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZfor = patch(dis.PolyXsideFB,dis.PolyYsideF,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZback = patch(dis.PolyXsideFB,dis.PolyYsideB,dis.PolyZside,satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZtop = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZbot = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),satColor,'FaceAlpha',satfacealpha,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha); 
            plt.XYZtop2 = patch(dis.PolyX,dis.PolyY,dis.PolyZtop,satColor,'FaceAlpha',facealpha1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
          
            hold(runMFax,'on')
            plt.ParticlePosA = scatter3('Parent',runMFax,dis.xunitA,dis.Ly-dis.yunitA,1.01*dis.zunitA,dis.Psize,dis.PcolorA ,'filled','Visible','on');
            plt.ParticlePosB = scatter3('Parent',runMFax,dis.xunitB,dis.Ly-dis.yunitB,1.01*dis.zunitB,dis.Psize,dis.PcolorB,'filled','Visible','on'); 
            plt.ParticlePosC = scatter3('Parent',runMFax,dis.xunitC,dis.Ly-dis.yunitC,1.01*dis.zunitC,dis.Psize,dis.PcolorC,'filled','Visible','on'); 
            
            plt.WellPosLine = plot3(runMFax,[dis.xposCent(dis.Qcol) dis.xposCent(dis.Qcol)],[dis.yposCent(dis.Qrow) dis.yposCent(dis.Qrow)],[dis.LzBot,dis.LzTop+Qscaled*Zextra],'Color',[1 0.2 0.2],'LineWidth',3);
            plt.WellPosDot = scatter3(runMFax,[dis.xposCent(dis.Qcol) ],[dis.yposCent(dis.Qrow) ],[dis.LzTop+Qscaled*Zextra],100,[1 0.2 0.2],'filled','MarkerEdgeColor','Black','LineWidth',1.3);
            text(dis.xposCent(dis.Qcol), dis.yposCent(dis.Qrow) ,1.1*(dis.LzTop+Qscaled*Zextra),[ num2str(dis.q,qfmtspec), '  m^3 day^-^1'])
            text(dis.xposCent(dis.Qcol), dis.yposCent(dis.Qrow) ,1.2*(dis.LzTop+Qscaled*Zextra),[ 'Well Discharge Rate: '])
            
            prepos = get(gca,'Position'); %workaround for legend auto changing axis position            
            legend([plt.XYZleft plt.ParticlePosA,plt.ParticlePosB,plt.ParticlePosC],['Saturated Thickness',dis.PLegendText],'Location',LegendLoc)
            set(gca,'Position',prepos);
            
        elseif check_vals == [1 0 1] %boundary conditions and particles
            plt.XYZleft = patch(dis.PolyXsideL(:,[1:dis.ncol:dis.nrow*dis.ncol]),dis.PolyYsideLR(:,[1:dis.ncol:dis.nrow*dis.ncol]),dis.PolyZside(:,[1:dis.ncol:dis.nrow*dis.ncol]),-1,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZright = patch(dis.PolyXsideR(:,[end:-dis.ncol:1]),dis.PolyYsideLR(:,[end:-dis.ncol:1]),dis.PolyZside(:,[end:-dis.ncol:1]),-1,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZfor = patch(dis.PolyXsideFB(:,[1:dis.ncol]),dis.PolyYsideF(:,[1:dis.ncol]),dis.PolyZside(:,[1:dis.ncol]),edgeindexFB,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZback = patch(dis.PolyXsideFB(:,[end-dis.ncol+1:end]),dis.PolyYsideB(:,[end-dis.ncol+1:end]),dis.PolyZside(:,[end-dis.ncol+1:end]),edgeindexFB,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZtop = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),dis.PolyZibound,'FaceAlpha',1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZbot = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),dis.PolyZibound,'FaceAlpha',1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);

            hold(runMFax,'on')
            
            plt.ParticlePosA = scatter3('Parent',runMFax,dis.xunitA,dis.Ly-dis.yunitA,1.01*dis.zunitA,dis.Psize,dis.PcolorA ,'filled','Visible','on');
            plt.ParticlePosB = scatter3('Parent',runMFax,dis.xunitB,dis.Ly-dis.yunitB,1.01*dis.zunitB,dis.Psize,dis.PcolorB,'filled','Visible','on'); 
            plt.ParticlePosC = scatter3('Parent',runMFax,dis.xunitC,dis.Ly-dis.yunitC,1.01*dis.zunitC,dis.Psize,dis.PcolorC,'filled','Visible','on'); 
            
            prepos = get(gca,'Position'); %workaround for legend auto changing axis position
            legend([plt.ParticlePosA,plt.ParticlePosB,plt.ParticlePosC],dis.PLegendText,'Location',LegendLoc)
            set(gca,'Position',prepos);
            
        elseif check_vals == [1 1 1] %all
            plt.XYZleft = patch(dis.PolyXsideL(:,[1:dis.ncol:dis.nrow*dis.ncol]),dis.PolyYsideLR(:,[1:dis.ncol:dis.nrow*dis.ncol]),dis.PolyZside(:,[1:dis.ncol:dis.nrow*dis.ncol]),-1,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZright = patch(dis.PolyXsideR(:,[end:-dis.ncol:1]),dis.PolyYsideLR(:,[end:-dis.ncol:1]),dis.PolyZside(:,[end:-dis.ncol:1]),-1,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZfor = patch(dis.PolyXsideFB(:,[1:dis.ncol]),dis.PolyYsideF(:,[1:dis.ncol]),dis.PolyZside(:,[1:dis.ncol]),edgeindexFB,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZback = patch(dis.PolyXsideFB(:,[end-dis.ncol+1:end]),dis.PolyYsideB(:,[end-dis.ncol+1:end]),dis.PolyZside(:,[end-dis.ncol+1:end]),edgeindexFB,'FaceAlpha',0.9,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);  
            plt.XYZtop = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),dis.PolyZibound,'FaceAlpha',1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZbot = patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),dis.PolyZibound,'FaceAlpha',1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);
            plt.XYZtop2 = patch(dis.PolyX,dis.PolyY,dis.PolyZtop,[1 1 1],'FaceAlpha',facealpha1,'Visible','on','Parent',runMFax,'EdgeAlpha',edgealpha);


            hold(runMFax,'on')
            
            plt.ParticlePosA = scatter3('Parent',runMFax,dis.xunitA,dis.Ly-dis.yunitA,1.01*dis.zunitA,dis.Psize,dis.PcolorA ,'filled','Visible','on');
            plt.ParticlePosB = scatter3('Parent',runMFax,dis.xunitB,dis.Ly-dis.yunitB,1.01*dis.zunitB,dis.Psize,dis.PcolorB,'filled','Visible','on'); 
            plt.ParticlePosC = scatter3('Parent',runMFax,dis.xunitC,dis.Ly-dis.yunitC,1.01*dis.zunitC,dis.Psize,dis.PcolorC,'filled','Visible','on'); 
            prepos = get(gca,'Position'); %workaround for legend auto changing axis position        
            legend([plt.ParticlePosA,plt.ParticlePosB,plt.ParticlePosC],dis.PLegendText,'Location',LegendLoc)
            set(gca,'Position',prepos);   
            
            plt.WellPosLine = plot3(runMFax,[dis.xposCent(dis.Qcol) dis.xposCent(dis.Qcol)],[dis.yposCent(dis.Qrow) dis.yposCent(dis.Qrow)],[dis.LzBot,dis.LzTop+Qscaled*Zextra],'Color',[1 0.2 0.2],'LineWidth',3);
            plt.WellPosDot = scatter3(runMFax,[dis.xposCent(dis.Qcol) ],[dis.yposCent(dis.Qrow) ],[dis.LzTop+Qscaled*Zextra],100,[1 0.2 0.2],'filled','MarkerEdgeColor','Black','LineWidth',1.3);
            text(dis.xposCent(dis.Qcol), dis.yposCent(dis.Qrow) ,1.1*(dis.LzTop+Qscaled*Zextra),[ num2str(dis.q,qfmtspec), '  m^3 day^-^1'])
            text(dis.xposCent(dis.Qcol), dis.yposCent(dis.Qrow) ,1.2*(dis.LzTop+Qscaled*Zextra),[ 'Well Discharge Rate: '])

        end
    end       
%% RESET BUTTON CALLBACK (reset all param values)
function reset_but_Callback(source,events)
% this function resets all parameter values to their initial values -
% cooresponds to the RESET BUTTON 
    %% reset al values to defaults and the ren callbacks to update info
    dis.KR = dis.KRbase;
    dis.KV = dis.KVbase;
    dis.KC = dis.KCbase;
    dis.Kbase = dis.KRbase;
    dis.Porosity = 0.25*dis.PorosityBase;

    Khet1_check.Value = 0 ;
    Khet2_check.Value = 0 ;

    dis.SS = dis.SSinit*dis.SSbase;
    dis.SY = dis.SYinit*dis.SYbase;

    dis.RCH = dis.RCHinit*dis.RCHbase;
    dis.q = dis.qinit; 

    Kcurr = find(dis.Kvals<=dis.Kinit);

    KR_slider.Value = Kcurr(end);

    SScurr =  find(log10(dis.SSvals)<log10(dis.SSinit));;
    SS_slider.Value = SScurr(end);


    SY_slider.Value = dis.SYinit;
    P_slider.Value = dis.Pinit;

    Qcurr = find(dis.Qvals<abs(dis.q));
    Q_slider.Value = Qcurr(end);

    rch_slider.Value = dis.RCHinit;

    dis.nper = 90;
    dis.perlen = 4;

    ELEV_slider.Value = dis.ELEVinit;


    nper_edit.String = dis.nper;
    perlen_edit.String = dis.perlen;
    tf_edit.String = dis.nper*dis.perlen;

    confined_check.Value = 0;

    % run callbacks 
    initial_slider_Callback;
    source_slider_Callback;
    param_slider_Callback;
    params_Callback;
    source_Callback;
    PreRunCheck_Callback;

    end
%% INITIAL SLIDER CALLBACK (update visuals on all tabs when initial conditions are changed) 
function initial_slider_Callback(source,events)
% this function updates the polygons in all 3-D visuals when the top elevation of the aquifer is changed in the Initial conditions tab) 
% upadtes info about confined/unconfined conditions and aquifer depth in
% the dis structure

   % get current top elevation of aquifer
  TopELEV = ceil(ELEV_slider.Value);
  ELEV_edit.String = num2str(TopELEV);
  ELEV_slider_txt.String = (['Elevation at Top of Aquifer  [' num2str(TopELEV),' m ]']);
  confined_check_txt.String = [' Aquifer is \bf \it {Confined}'];
  
  % deremine if aquider is confined or unconfined base don top elevation
  % and initial heads
  UNCFindex = find(dis.H<=TopELEV);
  dis.ELEVtop = reshape(dis.ELEVbase(:,:,1)',[],1);
  dis.ELEVtop(:) = TopELEV;
  
  dis.LzTop = TopELEV;
  dis.dv = abs(dis.ELEV(:,:,1)-dis.ELEV(:,:,2));
  dis.ELEV(:,:,1) = TopELEV*ones(size(dis.ELEV(:,:,1)));
  dis.ELEVsat = dis.ELEV;
  
% determine if unconfined conditions are met. Force unconfined if layer elevation exceed potentiometric surface 
if numel(UNCFindex)>0
    
    dis.ELEVsat(:,:,1) = dis.ELEV(:,:,1);
    dis.ELEVsat(UNCFindex) = dis.H(UNCFindex);
    confined_check.Value = 1;
    confined_check_txt.String = [' Aquifer is \bf \it {Unconfined}'];
    plt.XYZtopH2.Visible = 'on';
    %plt.surfHrunMF.Visible = 'off';
else
    confined_check.Value = 0;
    confined_check_txt.String = [' Aquifer is \bf \it {Confined}'];
    plt.XYZtopH2.Visible = 'off';
    
end

%update all axes with new elevations
axNames = {'runMFax','iboundax','paramsax','sourceax'};

for name = 1:length(axNames)
    
    cmdZLim = strjoin({'set(',cell2mat(axNames(name)),', ''ZLim'', sort([',num2str(dis.LzBot),' ', num2str(dis.LzTop),']))'},'');
    cmdZTick = strjoin({'set(',cell2mat(axNames(name)),', ''ZTick'', sort([',num2str(dis.LzBot),' ', num2str(dis.LzTop),']))'},'');    
    cmdZTickLabel = strjoin({'set(',cell2mat(axNames(name)),', ''ZTickLabel'',{''Bottom of Aquifer'',''Top of Aquifer''})'},'');
    XYaxNames = {'runMFax','initialax','paramsax','sourceax'};
    
    for j = 1:length(XYaxNames)       
        if  isequal(axNames(name),XYaxNames(j))==1 
           cmdZTick = strjoin({'set(',cell2mat(axNames(name)),', ''ZTick'', [dis.LzBot, dis.LzTop])'},'');
           cmdZTickLabel = strjoin({'set(',cell2mat(axNames(name)),', ''ZTickLabel'', [dis.LzBot, dis.LzTop])'},''); 
        end          
        eval(cmdZTick);
        eval(cmdZTickLabel);
    end    
    eval(cmdZLim);
    eval(cmdZTick);
    eval(cmdZTickLabel);
end


  if dis.LzTop == dis.Hmin
      [zticks , zind ] = sort( [dis.LzBot , dis.initPscale*dis.LzTop dis.Hmax]);
      zlabels = {['(Bottom of Aquifer)  ',num2str(dis.LzBot)],['(Top of Aquifer)  ',num2str(dis.LzTop)], num2str(dis.Hmax)};
      set(initialax,'ZLim',[dis.LzBot , 1.5*dis.Hmax],'ZTick',zticks,'ZTickLabel',zlabels(zind),'PlotBoxAspectRatio',[dis.LxNrm dis.LyNrm 0.6]);
  
  elseif dis.LzTop == dis.Hmax
      [zticks , zind ] = sort( [dis.LzBot , dis.Hmin , dis.Hmax]);
      zlabels = {['(Bottom of Aquifer)  ',num2str(dis.LzBot)],num2str(dis.Hmin),['(Top of Aquifer)  ',num2str(dis.LzTop)]};
      set(initialax,'ZLim',[dis.LzBot , 1.5*dis.Hmax],'ZTick',zticks,'ZTickLabel',zlabels(zind),'PlotBoxAspectRatio',[dis.LxNrm dis.LyNrm 0.6]);
  elseif dis.LzTop > dis.Hmax
      [zticks , zind ] = sort( [dis.LzBot , dis.Hmin , dis.Hmax, dis.LzTop]);
      zlabels = {['(Bottom of Aquifer)  ',num2str(dis.LzBot)],[num2str(dis.Hmin)],['(Max Sat Thickness)  ',num2str(dis.Hmax)],['(Top of Aquifer)  ',num2str(dis.LzTop)]};
      set(initialax,'ZLim',[dis.LzBot , 1.5*dis.Hmax],'ZTick',zticks,'ZTickLabel',zlabels(zind),'PlotBoxAspectRatio',[dis.LxNrm dis.LyNrm 0.6]);
  else
      [zticks , zind ] = sort( [dis.LzBot , dis.LzTop, dis.Hmin dis.Hmax]);
      zlabels = {['(Bottom of Aquifer)  ',num2str(dis.LzBot)],['(Top of Aquifer)  ',num2str(dis.LzTop)],['(Min. Head)  ',num2str(dis.Hmin)],['(Max Head)  ', num2str(dis.Hmax)]};
      set(initialax,'ZLim',[dis.LzBot , 1.5*dis.Hmax],'ZTick',zticks,'ZTickLabel',zlabels(zind),'PlotBoxAspectRatio',[dis.LxNrm dis.LyNrm 0.6]);
  end
  
  
% make new z verticies for sides of polygons
for k = 1:dis.nlay
    currElevTop = reshape(dis.ELEVsat(:,:,k)',1,[]);
    currElevBot = reshape(dis.ELEVsat(:,:,k+1)',1,[]);
    
    
    dis.PolyZside(1,:,k) = currElevTop;
    dis.PolyZside(2,:,k) = currElevBot;
    dis.PolyZside(3,:,k) = currElevBot;
    dis.PolyZside(4,:,k) = currElevTop; 
end

for k = 1:dis.nlay+1
    currElev = reshape(dis.ELEVsat(:,:,k)',1,[]);
    dis.PolyZ(1,:,k) = currElev;
    dis.PolyZ(2,:,k) = currElev;
    dis.PolyZ(3,:,k) = currElev;
    dis.PolyZ(4,:,k) = currElev;    
end

dis.PolyZtop(1,:) = .9999999*dis.ELEVtop;
dis.PolyZtop(2,:) = .9999999*dis.ELEVtop;
dis.PolyZtop(3,:) = .999999*dis.ELEVtop;
dis.PolyZtop(4,:) = .999999*dis.ELEVtop;


% update ELEV polygons
plt.XYZleftH.ZData = dis.initPscale*dis.PolyZside;
plt.XYZrightH.ZData = dis.initPscale*dis.PolyZside;
plt.XYZforH.ZData = dis.initPscale*dis.PolyZside;
plt.XYZbackH.ZData = dis.initPscale*dis.PolyZside;
plt.XYZtopH.ZData = dis.initPscale*dis.PolyZ(:,:,1);
plt.XYZbotH.ZData = dis.initPscale*dis.PolyZ(:,:,2);
plt.XYZtopH2.ZData = dis.PolyZtop;


plt.XYZleftIbound.ZData = dis.PolyZside(:,[1:dis.ncol:dis.nrow*dis.ncol]);% patch(dis.PolyXsideL(:,[1:dis.ncol:dis.nrow*dis.ncol]),dis.PolyYsideLR(:,[1:dis.ncol:dis.nrow*dis.ncol]),dis.PolyZside(:,[1:dis.ncol:dis.nrow*dis.ncol]),-1,'FaceAlpha',0.9,'Visible','on','Parent',iboundax,'EdgeAlpha',edgealpha);
plt.XYZrightIbound.ZData = dis.PolyZside(:,[end:-dis.ncol:1]);% patch(dis.PolyXsideR(:,[end:-dis.ncol:1]),dis.PolyYsideLR(:,[end:-dis.ncol:1]),dis.PolyZside(:,[end:-dis.ncol:1]),-1,'FaceAlpha',0.9,'Visible','on','Parent',iboundax,'EdgeAlpha',edgealpha);  
plt.XYZforIbound.ZData = dis.PolyZside(:,[1:dis.ncol]); %patch(dis.PolyXsideFB(:,[1:dis.ncol]),dis.PolyYsideF(:,[1:dis.ncol]),dis.PolyZside(:,[1:dis.ncol]),edgeindexFB,'FaceAlpha',0.9,'Visible','on','Parent',iboundax,'EdgeAlpha',edgealpha);
plt.XYZbackIbound.ZData = dis.PolyZside(:,[end-dis.ncol+1:end]);%patch(dis.PolyXsideFB(:,[end-dis.ncol+1:end]),dis.PolyYsideB(:,[end-dis.ncol+1:end]),dis.PolyZside(:,[end-dis.ncol+1:end]),edgeindexFB,'FaceAlpha',0.9,'Visible','on','Parent',iboundax,'EdgeAlpha',edgealpha);  
plt.XYZtopIbound.ZData = dis.PolyZ(:,:,1);%patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,1),dis.PolyZibound,'FaceAlpha',1,'Visible','on','Parent',iboundax,'EdgeAlpha',edgealpha);
plt.XYZbotIbound.ZData = dis.PolyZ(:,:,2);%patch(dis.PolyX,dis.PolyY,dis.PolyZ(:,:,2),dis.PolyZibound,'FaceAlpha',1,'Visible','on','Parent',iboundax,'EdgeAlpha',edgealpha);

plt.XYZleft.ZData = dis.PolyZside;
plt.XYZright.ZData = dis.PolyZside;
plt.XYZfor.ZData = dis.PolyZside;
plt.XYZback.ZData = dis.PolyZside;
plt.XYZtop.ZData = dis.PolyZ(:,:,1);
plt.XYZbot.ZData = dis.PolyZ(:,:,2);

plt.XYZleftKr.ZData = dis.PolyZside;
plt.XYZrightKr.ZData = dis.PolyZside;
plt.XYZforKr.ZData = dis.PolyZside;
plt.XYZbackKr.ZData = dis.PolyZside;
plt.XYZtopKr.ZData = dis.PolyZ(:,:,1);
plt.XYZbotKr.ZData = dis.PolyZ(:,:,2);

plt.XYZleftSS.ZData = dis.PolyZside;
plt.XYZrightSS.ZData = dis.PolyZside;
plt.XYZforSS.ZData = dis.PolyZside;
plt.XYZbackSS.ZData = dis.PolyZside;
plt.XYZtopSS.ZData = dis.PolyZ(:,:,1);
plt.XYZbotSS.ZData = dis.PolyZ(:,:,2);

plt.XYZleftSY.ZData = dis.PolyZside;
plt.XYZrightSY.ZData = dis.PolyZside;
plt.XYZforSY.ZData = dis.PolyZside;
plt.XYZbackSY.ZData = dis.PolyZside;
plt.XYZtopSY.ZData = dis.PolyZ(:,:,1);
plt.XYZbotSY.ZData = dis.PolyZ(:,:,2);

plt.XYZleftP.ZData = dis.PolyZside;
plt.XYZrightP.ZData = dis.PolyZside;
plt.XYZforP.ZData = dis.PolyZside;
plt.XYZbackP.ZData = dis.PolyZside;
plt.XYZtopP.ZData = dis.PolyZ(:,:,1);
plt.XYZbotP.ZData = dis.PolyZ(:,:,2);

plt.XYZleftRCH.ZData = dis.PolyZside;
plt.XYZrightRCH.ZData = dis.PolyZside;
plt.XYZforRCH.ZData = dis.PolyZside;
plt.XYZbackRCH.ZData = dis.PolyZside;
plt.XYZtopRCH.ZData = dis.PolyZ(:,:,1);
plt.XYZbotRCH.ZData = dis.PolyZ(:,:,2);

plt.XYZleftQ.ZData = dis.PolyZside;
plt.XYZrightQ.ZData = dis.PolyZside;
plt.XYZforQ.ZData = dis.PolyZside;
plt.XYZbackQ.ZData = dis.PolyZside;
plt.XYZtopQ.ZData = dis.PolyZ(:,:,1);
plt.XYZbotQ.ZData = dis.PolyZ(:,:,2);

% update layer type in dis structure (confined or unconfined) 
dis.laytyp = confined_check.Value;

% update modflow and modpath input files 
MPdis_Callback;
MFdis_Callback;

% update visuals in runMF tab 
PreRunCheck_Callback;

end
%% SOURCE CALLBACK
function source_Callback(source, events)
%% Callback function that handles the popup boxes for soureces 
% displays polygons,colormaps and labels for either Q or RCH 
%     Qval = Q_slider.Value;
%     RCHval = rch_slider.Value;

    % turn all off initially 
    RCH_edit.Visible = 'off';
    plt.RCHCbar.Visible = 'off';
    plt.QCbar.Visible = 'off';
    rch_slider.Visible = 'off';
    rch_slider_txt.Visible = 'off';
    Q_slider.Visible = 'off';
    Q_slider_txt.Visible = 'off';
    
    
    plt.XYZleftRCH.Visible = 'off'; 
    plt.XYZrightRCH.Visible = 'off';
    plt.XYZforRCH.Visible = 'off'; 
    plt.XYZbackRCH.Visible = 'off';
    plt.XYZtopRCH.Visible = 'off';
    plt.XYZbotRCH.Visible = 'off'; 

    Q_edit.Visible = 'off';
    plt.XYZleftQ.Visible = 'off'; 
    plt.XYZrightQ.Visible = 'off';
    plt.XYZforQ.Visible = 'off'; 
    plt.XYZbackQ.Visible = 'off';
    plt.XYZtopQ.Visible = 'off';
    plt.XYZbotQ.Visible = 'off';
    
    switch source_popup.Value
        case 1 %rch
        RCH_edit.Visible = 'on';
        rch_slider.Visible = 'on';
        rch_slider_txt.Visible = 'on';
        
        caxis(sourceax,dis.RCHlim);  
        colormap(sourceax,'parula');
        plt.RCHCbar.Visible = 'on';

        plt.XYZleftRCH.Visible = 'on'; 
        plt.XYZrightRCH.Visible = 'on';
        plt.XYZforRCH.Visible = 'on'; 
        plt.XYZbackRCH.Visible = 'on';
        plt.XYZtopRCH.Visible = 'on';
        plt.XYZbotRCH.Visible = 'on';
        
        case 2 %Q
        Q_edit.Visible = 'on';
        Q_slider.Visible = 'on';
        Q_slider_txt.Visible = 'on'; 
        
        caxis(sourceax,dis.Qlim);
         colormap(sourceax,'parula');
%         colormap(sourceax,parula(dis.Qvals));
        plt.QCbar.Visible = 'on';

        plt.XYZleftQ.Visible = 'on'; 
        plt.XYZrightQ.Visible = 'on';
        plt.XYZforQ.Visible = 'on'; 
        plt.XYZbackQ.Visible = 'on';
        plt.XYZtopQ.Visible = 'on';
        plt.XYZbotQ.Visible = 'on';
    end
             
end
%% PARAM  CALLBACK
function params_Callback(source, events)
%% Callback function that handles the popup boxes for soureces 
% displays polygons,colormaps and labels for either Q or RCH 

    % turn all off initially 
    KR_edit.Visible = 'off';
    KR_slider.Visible = 'off';
    KR_slider_txt.Visible = 'off';
    Kanis_edit.Visible = 'off';
    Kanis_edit_txt.Visible = 'off';
    Kanis_edit_arrowX.Visible = 'off';
    Kanis_edit_arrowY.Visible = 'off';
    KhetLabel_txt.Visible = 'off';
    Khet1_check.Visible = 'off';
    Khet1_txt.Visible = 'off';
    Khet2_check.Visible = 'off';
    Khet2_txt.Visible = 'off';
    Khet12_check.Visible = 'off';
    Khet12_txt.Visible = 'off';   
    
    SS_edit.Visible = 'off';
    SS_slider.Visible = 'off';
    SS_slider_txt.Visible = 'off';
    SY_slider.Visible = 'off';
    SY_slider_txt.Visible = 'off';  
    P_slider.Visible = 'off';
    P_slider_txt.Visible = 'off';    

    plt.XYZleftKr.Visible = 'off'; 
    plt.XYZrightKr.Visible = 'off';
    plt.XYZforKr.Visible = 'off'; 
    plt.XYZbackKr.Visible = 'off';
    plt.XYZtopKr.Visible = 'off';
    plt.XYZbotKr.Visible = 'off'; 


    plt.SSCbar.Visible = 'off';
    plt.XYZleftSS.Visible = 'off';
    plt.XYZrightSS.Visible = 'off'; 
    plt.XYZforSS.Visible = 'off'; 
    plt.XYZbackSS.Visible = 'off';
    plt.XYZtopSS.Visible = 'off';
    plt.XYZbotSS.Visible = 'off';
    
    SY_edit.Visible = 'off';
    plt.SYCbar.Visible = 'off';
    plt.XYZleftSY.Visible = 'off';
    plt.XYZrightSY.Visible = 'off'; 
    plt.XYZforSY.Visible = 'off'; 
    plt.XYZbackSY.Visible = 'off';
    plt.XYZtopSY.Visible = 'off';
    plt.XYZbotSY.Visible = 'off';  
    
    P_edit.Visible = 'off';
    plt.PCbar.Visible = 'off';
    plt.XYZleftP.Visible = 'off';
    plt.XYZrightP.Visible = 'off'; 
    plt.XYZforP.Visible = 'off'; 
    plt.XYZbackP.Visible = 'off';
    plt.XYZtopP.Visible = 'off';
    plt.XYZbotP.Visible = 'off';
    
    switch params_popup.Value
   
        case 1 %K
            
            KR_edit.Visible = 'on';
            KR_slider.Visible = 'on';
            KR_slider_txt.Visible = 'on';
            Kanis_edit.Visible = 'on';
            Kanis_edit_txt.Visible = 'on';
            Kanis_edit_arrowX.Visible = 'on';
            Kanis_edit_arrowY.Visible = 'on';
            KhetLabel_txt.Visible = 'on';
            Khet1_check.Visible = 'on';
            Khet1_txt.Visible = 'on';
            Khet2_check.Visible = 'on';
            Khet2_txt.Visible = 'on';
            Khet12_check.Visible = 'on';
            Khet12_txt.Visible = 'on';             
            plt.KCbar.Visible = 'on';
            colormap(paramsax,'summer');
            caxis(paramsax,dis.Klim);
         
            plt.XYZleftKr.Visible = 'on'; 
            plt.XYZrightKr.Visible = 'on';
            plt.XYZforKr.Visible = 'on'; 
            plt.XYZbackKr.Visible = 'on';
            plt.XYZtopKr.Visible = 'on';
            plt.XYZbotKr.Visible = 'on'; 

            
            
        case 2 % SS
           SS_edit.Visible = 'on';
           SS_slider.Visible = 'on';
           SS_slider_txt.Visible = 'on';
           plt.SSCbar.Visible = 'on';
           colormap(paramsax,'winter');
           caxis(paramsax,dis.SSlim);
           dis.SSlim
            plt.XYZleftSS.Visible = 'on';
            plt.XYZrightSS.Visible = 'on'; 
            plt.XYZforSS.Visible = 'on'; 
            plt.XYZbackSS.Visible = 'on';
            plt.XYZtopSS.Visible = 'on';
            plt.XYZbotSS.Visible = 'on';
            
        case 3 % SY 
           SY_edit.Visible = 'on';
           SY_slider.Visible = 'on';
           SY_slider_txt.Visible = 'on';
           plt.SYCbar.Visible = 'on';
%            plt.SYCbar.Label.String = 'Specific Yield (%)';
           colormap(paramsax,'autumn');
           caxis(paramsax,dis.SYlim);

            plt.XYZleftSY.Visible = 'on';
            plt.XYZrightSY.Visible = 'on'; 
            plt.XYZforSY.Visible = 'on'; 
            plt.XYZbackSY.Visible = 'on';
            plt.XYZtopSY.Visible = 'on';
            plt.XYZbotSY.Visible = 'on';
            
        case 4 % Porosity 
           P_edit.Visible = 'on';
           P_slider.Visible = 'on';
           P_slider_txt.Visible = 'on';            
           plt.PCbar.Visible = 'on';
%          plt.PCbar.Label.String = 'Storativity (unitless)';
           colormap(paramsax,'spring');
           caxis(paramsax,dis.Plim);
           
            plt.XYZleftP.Visible = 'on';
            plt.XYZrightP.Visible = 'on'; 
            plt.XYZforP.Visible = 'on'; 
            plt.XYZbackP.Visible = 'on';
            plt.XYZtopP.Visible = 'on';
            plt.XYZbotP.Visible = 'on';
    end
    
    
                
        
end
%% DISCRETIZE MODPATH CALLBACK
function MPdis_Callback(source,events)
% regenerate initial positions of particles based on top elevation of
% aquifer

% particles z-coortinates are scaled to be equal to half the saturated thickness of
% the aquifer


%generate initial particle positions (circle)
dis.pzA = median(unique(dis.ELEVsat(:,:,1)))/2;  %depth
dis.pzB = median(unique(dis.ELEVsat(:,:,1)))/2;  %depth
dis.pzC = median(unique(dis.ELEVsat(:,:,1)))/2;  %depth

dis.randthA = 2*pi*rand(1,MPin.ParticleCountA);
dis.thA = linspace(0,2*pi,MPin.ParticleCountA);

dis.randthB = 2*pi*rand(1,MPin.ParticleCountB);
dis.thB = linspace(0,2*pi,MPin.ParticleCountB);

dis.randthC = 2*pi*rand(1,MPin.ParticleCountC);
dis.thC = linspace(0,2*pi,MPin.ParticleCountC);

dis.xunitA = dis.prA*(rand(1,MPin.ParticleCountA).^0.5) .* cos(dis.randthA) + dis.pxA;
dis.yunitA = dis.prA*(rand(1,MPin.ParticleCountA).^0.5) .* sin(dis.randthA) + dis.pyA;
dis.zunitA = dis.pzA*ones(size(dis.randthA));

dis.xunitB = dis.prB*(rand(1,MPin.ParticleCountB).^0.5) .* cos(dis.randthB) + dis.pxB;
dis.yunitB = dis.prB*(rand(1,MPin.ParticleCountB).^0.5) .* sin(dis.randthB) + dis.pyB;
dis.zunitB = dis.pzB*ones(size(dis.randthB));

dis.xunitC = dis.prC*(rand(1,MPin.ParticleCountC).^0.5) .* cos(dis.randthC) + dis.pxC;
dis.yunitC = dis.prC*(rand(1,MPin.ParticleCountC).^0.5) .* sin(dis.randthC) + dis.pyC;
dis.zunitC = dis.pzC*ones(size(dis.randthC));

end
%% DISCRETIZE MODFLOW CALLBACK (update time discretization)
function MFdis_Callback(source,events)
% update time discretization and aquifer properties from runMF tab 
    nper = ceil(str2num(nper_edit.String));
    disp(nper)
    perlen = str2num(perlen_edit.String);
    if nper == 0
        nper = 1;
    elseif nper <0 
        nper = abs(nper);
    end
    
    if perlen == 0
        perlen = 1;
    elseif perlen <0
        perlen = abs(perlen);
    end
    dis.nper = nper;
    dis.perlen = perlen;
       
    nper_edit.String = num2str(nper);
    perlen_edit.String = num2str(perlen);
    tf_edit.String = num2str(nper*perlen);
      

    confined_check.Value
    dis.laytyp = confined_check.Value;
    
end
%% RUN MODFLOW CALLBACK


runMFcounter = 0;% counter to track whether results window has been generated
function runMF_Callback(source,events)
% funciton takes all user input and passes it to support library for constructing
% MODFLOW and MODPATH input files. 
  
MFin.nrow = dis.nrow; MFin.ncol = dis.ncol; MFin.nlay = dis.nlay;
MFin.dim = dis.nrow*dis.ncol*dis.nlay;
MFin.Lx = dis.Lx; MFin.Ly = dis.Ly;
MFin.dr = dis.dr; MFin.dc = dis.dc;
MFin.laycbd=[0]; %1 indicates presence of confining layer below. Must be 0 for bottom layer (only layer in this case);

MFin.laytyp = [dis.laytyp]; %unconfined (convertable) =/=0 , confined=0  (top to bot)
MFin.ibound = dis.ibound;
MFin.top = ELEV_slider.Value*ones(size(dis.ELEV(:,:,1)));
MFin.bot = dis.ELEV(:,:,2:end);
MFin.Ss = dis.SS;
MFin.Sy = dis.SY;
MFin.KR = dis.KR;
MFin.KC = dis.KC;
MFin.KV = dis.KV;
MFin.quasiKV=zeros(MFin.nrow,MFin.ncol,MFin.nlay); %hydraulic conductivity for quasi 3d confing layers
MFin.H0 = dis.H;
MFin.nper = dis.nper+1; %number of stress periods.
MFin.perlen = repmat(dis.perlen,MFin.nper,1); % period length (days)
MFin.nsteps = repmat(dis.nsteps,MFin.nper,1); %number of solver calls per step
MFin.TrSs = repmat({'Tr'},MFin.nper,1); %

MFin.nwell = 1;
MFin.welllayer = repmat([1 ],MFin.nper,1);
MFin.wellcol = repmat(dis.Qcol ,MFin.nper,1);
MFin.wellrow = repmat(dis.Qrow ,MFin.nper,1);
MFin.Q = repmat(dis.q ,MFin.nper,1);
MFin.rech = repmat(dis.RCH, 1,1,MFin.nper);
MFin.PauseBat = 'exit';
MFin.filename = 'gui_ex1';
MFin.dumrun = 0;
MFout = Format_ModFlow(MFin);


%make first period steady state
MFin.Q(1) = 0;
MFin.TrSs(1) = {'Ss'};
MFin.perlen(1) = 0.1% set SS stress period length to be very short 


%modpath
MPin.PauseBat='exit';
MPin.filename=MFin.filename;
MPin.ShellFlag=0; %ShellFlag=1 if shell is used to execute MODPATH. 
MPin.trackingdir='for';
MPin.porosity= dis.Porosity';%.25*ones(size(MFin.H0));
MPin.timepoints = [0 : dis.perlen : dis.nper*dis.perlen];


MPdis_Callback % update particle positions 
MPin.XYZin = [dis.xunitA dis.xunitB dis.xunitC; dis.yunitA dis.yunitB dis.yunitC ;dis.zunitA dis.zunitB dis.zunitC];
MPin.XYZinA = [dis.xunitA ; dis.yunitA  ;dis.zunitA ];
MPin.XYZinB = [dis.xunitB ; dis.yunitB  ;dis.zunitB ];
MPin.XYZinC = [dis.xunitC ; dis.yunitC  ;dis.zunitC ];

% convert glbal xyz to model row-col-lay coordinates 
for i=1:MPin.ParticleCount
        [IndIn(i,:),SubIn(i,:),LocIn(i,:)] = GlobalXYZ2ind(MPin.XYZin(:,i),MFout);
end

    %%
MPin.InitialCellNumber = IndIn;
MPin.InitialLocalXYZ = LocIn;
MPin.reftime = 0;
MPin.stoptime = MPin.timepoints(end);
MPin.releasetime = 0;

MPin.zones = zeros(size(dis.ibound'));
MPin.zones(1,1:end) = 2; MPin.zones(end,1:end) = 2;
MPin.zones(dis.Qind) = 3;
MPin.stopzone = 0;

dis.initialax=initialax;
% close output window if new run (after the first run) is made
if  runMFcounter >0
    if ishandle(2) == 1
    close('GW Tutor -- Output')
    end
end


[MFfig] = GWTutor_OUTPUT_GUI(dis,plt,MFin,MPin);
runMFcounter = 1; % update counter  

end
%% END



%% Check that MODFLOW and MODPATH executables are in the current directory %%



    

%check = exist(modelDirectory,'dir');



%% display figure if executables are found 
if executable_warning == 0
    mainfig.Visible = 'on';
end 


end




