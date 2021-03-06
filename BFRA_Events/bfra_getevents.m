function [T,Q,R,Info] = bfra_getevents(t,q,r,varargin)
%BFRA_GETEVENTS returns flow Q and time T values of each individual
%recession event, and info about the applied filters.

% Inputs:
%  t           =  time
%  q           =  flow
%  r           =  rain
%  opts        =  (optional) structure containing the following fields:
%  qmin        =  minimum flow value, below which values are set nan
%  nmin        =  minimum event length
%  fmax        =  maximum # of missing values gap-filled
%  rmax        =  maximum run of sequential constant values
%  rmin        =  minimum rainfall required to censor flow
%  cmax        =  maximum run of sequential convex dQ/dt values
%  rmconvex    =  remove convex derivatives
%  rmnochange  =  remove consecutive constant derivates
%  rmrain      =  remove rainfall
%  pickevents  =  option to manually pick events
%  plotevents  =  option to plot picked events
   
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% input handling
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
p = MipInputParser;
p.FunctionName    = 'bfra_getevents';
p.CaseSensitive   = true;              % true because T,Q,R are sent back
p.addRequired( 't',                    @(x) isnumeric(x) | isdatetime(x));
p.addRequired( 'q',                    @(x) isnumeric(x) & numel(x)==numel(t));
p.addRequired( 'r',                    @(x) isnumeric(x)                );
p.addParameter('qmin',        0,       @(x) isnumeric(x) & isscalar(x)  );
p.addParameter('nmin',        4,       @(x) isnumeric(x) & isscalar(x)  );
p.addParameter('fmax',        2,       @(x) isnumeric(x) & isscalar(x)  );
p.addParameter('rmax',        2,       @(x) isnumeric(x) & isscalar(x)  );
p.addParameter('rmin',        0,       @(x) isnumeric(x) & isscalar(x)  );
p.addParameter('cmax',        2,       @(x) isnumeric(x) & isscalar(x)  );
p.addParameter('rmconvex',    false,   @(x) islogical(x) & isscalar(x)  );
p.addParameter('rmnochange',  true,    @(x) islogical(x) & isscalar(x)  );
p.addParameter('rmrain',      false,   @(x) islogical(x) & isscalar(x)  );
p.addParameter('pickevents',  false,   @(x) islogical(x) & isscalar(x)  );
p.addParameter('plotevents',  false,   @(x) islogical(x) & isscalar(x)  );
p.parseMagically('caller');
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
% iF is the first non-nan index, to recover indices after removing nans
   q(q<qmin)   = nan;                      % set values < qmin nan
   q           = setconstantnan(q,rmax);   % set constant non-nan values nan
   [t,q,r,iF]  = rmleadingnans(t,q,r);     % remove leading nans 
   [t,q,r]     = rmtrailingnans(t,q,r);    % remove trailing nans
   q           = fillnans(q,fmax);         % gap fill missing values
   q           = smoothflow(q);            % apply a smoothing filter
    
    if isempty(q)||sum(~isnan(q))<nmin     % fast exit
        [T,Q,R,Info] = seteventnan;        % note this returns [] not nan
    else
        
        % call eventfinder either way, then update if pickfits == true
        [T,Q,R,Info] = eventfinder(t,q,r, 'nmin',        nmin,          ...
                                          'fmax',        fmax,          ...
                                          'rmax',        rmax,          ...
                                          'rmin',        rmin,          ...
                                          'rmconvex',    rmconvex,      ...
                                          'rmnochange',  rmnochange,    ...
                                          'rmrain',      rmrain         );
        
        Info         = updateinfo(Info,iF);

        % NOTE: eventpicker doesn't update Info for events that are picked
        % within an eventfinder event, but only Info.istart is used in the
        % main algorithm so it is sufficient at this point
        if pickevents == true
           [T,Q,R,Info] =  eventpicker(t,q,r,nmin,Info);
        elseif plotevents == true
           Info.hEvents =  eventplotter(t,q,r,Info,'plotevents',plotevents);
        end
    end
end

function Info = updateinfo(Info,ifirst)

   fields = fieldnames(Info);
   
   for m = 1:numel(fields)
      Info.(fields{m}) = Info.(fields{m}) + ifirst - 1;
   end
   
   Info.runlengths   = Info.istop - Info.istart + 1;
   Info.ifirst       = ifirst;
   
end