function [x,y,logx,logy,weights,success] = bfra_prepfits(q,dqdt,varargin)

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   p = MipInputParser;
   p.addRequired('q',                           @(x)isnumeric(x)  );
   p.addRequired('dqdt',                        @(x)isnumeric(x)  );
   p.addParameter('weights',  ones(size(q)),    @(x)isnumeric(x)  );
   p.addParameter('mask',     true(size(q)),    @(x)islogical(x)  );
   p.parseMagically('caller');
   
   weights = p.Results.weights;
   mask = p.Results.mask;
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   % take the negative dq/dt values
   ok          = dqdt<0;
   x           = abs(q(ok));
   y           = abs(dqdt(ok));
   weights     = weights(ok);
   mask        = mask(ok);
   
   % convert the mask to weights
   weights(mask==false) = 0;
   
   logx        = log(x);
   logy        = log(y);
   
   [  x,    ...
      y,    ...
      weights ]   = prepareCurveData( x, y, weights );
     
     
   [  logx, ...
      logy, ...
      weights ]   = prepareCurveData(logx,logy,weights);
   

   success  = true;
   if numel(y)<4 % || numnodif >4
      success = false;
   end
   
end
