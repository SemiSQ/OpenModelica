function [x,y,val,steps] = get_grid(dymstr,fieldname,varargin)
% get_grid  Get the grid from a FDM field
% get_grid(dymstr,fieldname), where dymstr is the dymola struct loaded by
% dymload(), and fieldname is the name of the field. The grid is then found
% in fieldname.domain.grid.
gridname=[fieldname, '.domain.grid'];
xnodename=[gridname, '.x1'];
ynodename=[gridname, '.x2'];
nname=[gridname, '.n'];
valname=[fieldname, '.val'];

xc=dymget(dymstr,xnodename);
yc=dymget(dymstr,ynodename);
valc=dymget(dymstr,valname);
nc=dymget(dymstr,nname);

xd=cell2mat(xc);
yd=cell2mat(yc);
vald=cell2mat(valc);
nd=cell2mat(nc);
nx=nd(1,1);
ny=nd(1,2);

% get the number of result values 
maxstepno=size(valc{1,1},1);
stepno=2; % always at least 2. take the second one by default
if nargin == 3
    stepno=varargin{1};
    if (stepno > maxstepno)
        error('Too big time index');
    end
end

x=xd(2,:);
y=yd(2,:);
val=vald(stepno:maxstepno:nx*maxstepno,:);
steps=maxstepno;