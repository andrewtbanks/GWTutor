function [ struct ] = Format_Modpath( in )
% formats input data from GUI into a strucutre readable by functions that
% write MODPATH input files. 

% data is sorted based on what modflow input files it corresponds to 
% variable names in the output strucutre(struct) match very closely to what is
% used in the MODPATH 6 documentation.

%% SPECIFY IF MODPATH IS EXECUTED BY SHELL
struct.ShellFlag=in.ShellFlag;

%% BAT execution
struct.MPBAT.PAUSE=in.PauseBat;
struct.MPBAT.IDpath=strsplit(pwd,'\');
struct.MPBAT.IDpath(end+1)={in.filename};
struct.MPBAT.IDpath(end+1)={strcat(in.filename,'ID.txt')};
struct.MPBAT.IDpath=strjoin(struct.MPBAT.IDpath,'\');
%% NAM. FILE
struct.MPNAM.filename=in.filename;

%%  MPBAS. FILE
struct.MPBAS.POR=in.porosity; %array of porosity values
struct.MPBAS.IFACE=0;

%% SLOC. FILE
struct.SLOC.LocationStyle=2;%in.LocationStyle; %2 uses cell number , 1 uses [layer, row column] cols=3 rows=Particlecount
struct.SLOC.ParticleIdOption=1;
if struct.ShellFlag==0 %case where MODPATH is not executed using a shell;
    struct.SLOC.InitialLocalXYZ=in.InitialLocalXYZ;
    struct.SLOC.ParticleCount=in.ParticleCount;
    struct.SLOC.TimeOffset=repmat(0.0,1,struct.SLOC.ParticleCount);
    struct.SLOC.Drape=repmat(0,1,struct.SLOC.ParticleCount);
    if struct.SLOC.LocationStyle==1;  
        struct.SLOC.InitialSub=in.InitialSub; %[layer row column]   
    elseif struct.SLOC.LocationStyle==2;
        struct.SLOC.InitialCellNumber=in.InitialCellNumber;   
    end
    if struct.SLOC.ParticleIdOption==1;
    struct.SLOC.ParticleID=[1:1:struct.SLOC.ParticleCount];
    end
end    
%% MPSIM. FILE
struct.MPSIM.TIMEPOINTOPTION=2;
struct.MPSIM.STOPTIMEOPTION=3;  
struct.MPSIM.ZONES = in.zones;% array of integers for each cell with zone designations
struct.MPSIM.STOPZONE = in.stopzone; % integer specifying zone to terminate particles in (0 = no termination)
struct.MPSIM.TRACKINGDIR=in.trackingdir; 

if struct.ShellFlag==0 
if struct.MPSIM.TIMEPOINTOPTION==1
    struct.MPSIM.NTIMEPOINTS=in.ntimepoints;
    struct.MPSIM.TIMESTEP=in.timestep;
elseif struct.MPSIM.TIMEPOINTOPTION==2
    struct.MPSIM.TIMEPOINTS=in.timepoints;
end
struct.MPSIM.REFTIME=in.reftime;  
struct.MPSIM.RELEASETIME=in.releasetime;
 %case where MODPATH is not executed using a shell;
  if struct.MPSIM.STOPTIMEOPTION==3
    struct.MPSIM.STOPTIME=in.stoptime;
  end
end

