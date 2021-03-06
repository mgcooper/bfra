function intercept = reflineintercept(x,y,slope,refpoint,modeltype,xyref)
   
% this finds the value of the y-data that is nearest to yrefpoint, then
% finds the matching x-value, then forces the line to pass through that
% point.
   
   if nargin == 5
      xyref = 'y';
   end
   
   switch xyref
      
      case 'y'
      
      switch modeltype

         case 'power'
            intercept = refpoint/x(findmin(abs(y-refpoint),1,'first'))^slope;

         case 'linear'
            intercept = refpoint-x(findmin(abs(y-refpoint),1,'first'))*slope;
      end   
      
      case 'x'
      
      switch modeltype

         case 'power'
            intercept = y(findmin(abs(y-refpoint),1,'first'))/refpoint^slope;

         case 'linear'
            intercept = y(findmin(abs(y-refpoint),1,'first'))-refpoint*slope;
      end   
      
      
   end
   
end
