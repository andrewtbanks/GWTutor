function [  ] = ClearModFlow(filename)
% Author: Andy Banks 2019 - Univeristy of Kansas Dept of Geology 
% GWTutor MODFLOW/MODPATH support library 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% deletes any modflow files in current directory with matching filename
[out,msg,msgID]=rmdir([pwd,'\',filename],'s');

if out==1
    disp([num2str(filename),' deleted using ClearModFlow'])
elseif out==0
    disp(['Unable to delete directory for ',num2str(filename)])
    disp(['   msg: ',msg])
    disp(['   msgID: ',msgID])
end
end

