function [ struct ] = Format_ModFlow(in)
% formats input data from GUI into a structure readable by functions that
% write modflow input files. 

% data is sorted based on what modflow input files it corresponds to) 
% variable names in the output strucutre(struct) match very closely to what is
% used in the MODFLOW 2005 documentation.

%% BAT execution
if in.dumrun==0 % dumrun variable toggles whether the .bat file insetrs a puase after execution 
struct.BAT.PAUSE=in.PauseBat;

%% NAM. FILE
struct.NAM.filename=in.filename;

end
%% DIS. FILE
struct.DIS.NLAY=in.nlay;
struct.DIS.NROW=in.nrow;
struct.DIS.NCOL=in.ncol;
struct.DIS.DIM=in.dim;

struct.DIS.NPER=in.nper; %#of stress periods in simulation
struct.DIS.TrSs=in.TrSs; %period type (transient or SS)
struct.DIS.ITMUNI=4;%time unit (0=undefined,1=seconds,2=min,3=hour,4=day)
struct.DIS.LENUNI=2;%length unit (0=undefined,1=feet,2=meters)

struct.DIS.DELR=in.dr;%single value not vectors
struct.DIS.DELC=in.dc; 
struct.DIS.TOP=in.top;
struct.DIS.BOT=in.bot;%bottom elevation

struct.DIS.PERLEN=in.perlen;%stress period lengths
struct.DIS.NSTP=in.nsteps;%# of timesteps in corresponding stress period
struct.DIS.TSMULT=ones(1,in.nper);% multiplier for length of sucessive steps (keep 1.0 for constant step size.... probably doesnt matter if NSTP=1)
struct.DIS.LAYCBD=in.laycbd;% flag (1) indicating whether the layer has quasi 3-d confining bed below (must be 0 for bottom layer


%% BA6. FILE
struct.BA6.X=in.H0;%ICS
struct.BA6.HNOFLO=9999; %HNOFLOW (constant boundary heads);
struct.BA6.HDRY=1.0E-30; %HDRY value assigned to dry cells;
struct.BA6.IBOUND=in.ibound; % array of boundary 
%% WEL. FILE
if in.dumrun==0

struct.WEL.MXACTW=in.nwell;
struct.WEL.LAYER=in.welllayer;
struct.WEL.ROW=in.wellrow;
struct.WEL.COLUMN=in.wellcol;
struct.WEL.Q=in.Q;
end

%% LPF. FILE
struct.LPF.LAYTYP=in.laytyp; %0 if confined >0 if unconfined 
struct.LPF.LAYAVG=repmat(0,1,struct.DIS.NLAY); % Method of calculating interblock transmissivity (0 is harmnic mean)...(bot to top)
struct.LPF.CHANI=repmat(0,1,struct.DIS.NLAY); %horizontal anisotropy coeffienct for whole layer (0) inicates HANI must be used;
struct.LPF.VKA=in.KC./in.KV; %ratio of horizaontal to vertical hydraulic conductivity

struct.LPF.LAYVKA=repmat(0,1,struct.DIS.NLAY); %flag for whether VKA is vertical hydraulic conductivity or ratio VK/HK ( 0 indicates using VK)
struct.LPF.LAYWET=repmat(0,1,struct.DIS.NLAY); %contains a flag for each layer that indicates if wetting is active (not 0 indicates wetting is inactive)
struct.LPF.HK=in.KR; %horizontal hydraulic conductivity 
struct.LPF.HANI=in.KC./in.KR; %ratio of K along columns to K along rows
struct.LPF.VKA=in.KV; %vertical hydraulic conductivity
struct.LPF.quasiVKA=in.quasiKV; %vertical hydraulic conductivity in quasi 3D confining layers
struct.LPF.Ss=in.Ss;%specific storage
struct.LPF.Sy=in.Sy;%specific yeild

%% OC FILE 
struct.OC.RETURNPER=1:struct.DIS.NPER;% return periods to save heads for 
struct.OC.RETURNSTEP=struct.DIS.NSTP;%struct.DIS.NSTP; %corresponding steps to print

%% PCG. FILE
struct.PCG.MXITER=250;%maximum number of iterations to call for PCG solution routine
struct.PCG.HCLOSE=1;%head change criterion for convergence in units of length (LENUNI)
struct.PCG.RCLOSE=1;%residual criterion for convergence

%% RCH. FILE
if in.dumrun==0
 struct.RCH.NPRCH=0;%in.nprch;
 struct.RCH.NRCHOP=1; %recharge option code (1== recharge only to top grid layer)
 struct.RCH.IRCHB=11; %flag to save cell be cell flow terms
struct.RCH.INRECH=1; %flag indigating how recharge rates are read; (1 means read for each stress period) 
struct.RCH.RECH=in.rech; %read array of recharge values for each stress period 

end



for i=1:length(struct.RCH.NPRCH);
struct.RCH.PARNAM{i}=strcat('RCHpar',num2str(i)); %name of parameter to be defined
% struct.RCH.Parval(i)=in.rchparval(i); %recharge parameter value
end
struct.RCH.NCLU=1;
struct.RCH.PARTYP='RCH'; %type of parameter to be defined 'RCH;'

struct.RCH.NCLU;



end

