function [phi,solns,desc] = bfra_fitphi(a1,a2,b2,A,D,L,varargin)
%BFRA_FITPHI estimates drainable porosity phi using an early-time and
%late-time solution. input 'soln' is the early-time

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   p = MipInputParser;
   p.StructExpand = false;
   p.FunctionName = 'bfra_fitphi';
   p.addRequired('a1',@(x)isnumeric(x));
   p.addRequired('a2',@(x)isnumeric(x));
   p.addRequired('b2',@(x)isnumeric(x));
   p.addRequired('A',@(x)isnumeric(x));
   p.addRequired('D',@(x)isnumeric(x));
   p.addRequired('L',@(x)isnumeric(x));
   p.addParameter('theta',0,@(x)isnumeric(x));
   p.addParameter('isflat',true,@(x)islogical(x));
   p.addParameter('dispfit',false,@(x)islogical(x));
   p.addParameter('soln1','Rupp and Selker, 2005',@(x)ischar(x));
   p.addParameter('soln2','Rupp and Selker, 2005',@(x)ischar(x));
   p.parseMagically('caller');
   soln1 = p.Results.soln1;
   soln2 = p.Results.soln2;
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% b1  = early-time b (not needed for any solutions but assumed)
% b2  = late-time b
% a1  = early-time a
% a2  = late-time a

% options for early-time solution:
%  Polubarinova-Kochina, 1962 (nonlinear, flat, constant k(z), b=3)
%  Rupp and Selker, 2005      (nonlinear, flat, k(z)=(Z/D)^n, b=3)
%  Brutsaert, 1994            (linearized, sloped, constant k(z), b=3)

% options for late-time solution:
%  Boussinesq, 1903           (linearized, flat, constant k(z), b=1)
%  Boussinesq, 1904           (nonlinear, flat, constant k(z), b=3/2)
%  Rupp and Selker, 2005      (nonlinear, flat, k(z)=(Z/D)^n, b=(2n+3)/(n+2)
%  Rupp and Selker, 2006      (nonlinear, sloped, b=(2n+1)/(n+1) 
%  Rupp and Selker, 2006 b=1  (nonlinear, sloped, b=1)
%  Brutsaert, 1994            (linearized, sloped, constant k(z), b=1)

% * denotes ones that are implemented
% so we have these early/late options for flat
% *PK62 / BS04   constant k(z) + nonlinear early and late
% *PK62 / BS03   constant k(z) + nonlinear early, constant k(z) + linear late
% *RS05 / RS05   k(z)=(Z/D)^n + nonlinear early and late
% PK62 / RS05   constant k(z) + nonlinear early, k(z)=(Z/D)^n + nonlinear late

% and these early/late options for sloped:
% *BR94 / BR94   constant k(z) + linearized early and late
% *BR94 / RS06   constant k(z) + linearized early, k(z)~Z^n + nonlinear late
% *BR94 / RS06b1 constant k(z) + linearized early, k(z)~Z^n + nonlinear late

% and these options for sloped early, flat late:
% BR94 / BS04   constant k(z) + linearized early; constant k(z) + nonlinear late
% BR94 / BS03   constant k(z) + linearized early; constant k(z) + linearized late
% BR94 / RS05   constant k(z) + linearized early; k(z)~Z^n + nonlinear late

% see subroutine allsolutions to build all possible combos

% the two soln options dictate the early-time expression for 'a'. the
% late-time value is dictated by 'blate', but warn the user in case

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% parse the soln options
   [solns,desc,b2]  = parsesolutions(soln1,soln2,b2,isflat);

% solve for phi given the requested solutions
   numsoln  = numel(solns);
   phi      = nan(numsoln,1);

for m = 1:numsoln

   soln = solns{m};
   
   switch soln
   
      % NOTE: this is probably not a valid choice, because B94 is for
      % homogeneous soils whereas RS06 is heterogeneous.
      case 'BR94_RS06'        % Brutsaert 1994, early-time, b=3
         n     = bfra_conversions(b2,'b','n','isflat',false);
        
         
         % a1 = 1.133/(k*phi*D^3*L^2*cos(theta))
         n1    = n+1;
         n2    = n+1/100;
         n3    = 1/(n+2);
         n4    = 1/(n+1);
         n5    = n+3;
         c1c2  = (n1^2/(n2*A)*(2.266*tand(theta)/(n1*L*D^n5))^n4)^n3;
         a1a2  = (a1^n4*a2)^n3;
         
         
      case 'BR94_RS06b1'

         c1c2  = sqrt(200*tand(theta)*1.133/(L*A*D^3));
         a1a2  = sqrt(a1*a2);
         
      case 'BR94_BR94'
         eta   = A*tand(theta)/(2*L*D);
         p     = 1/3;
         c1c2  = sqrt(1.133)*(pi*p+eta)/(D*A*sqrt(p));
         a1a2  = sqrt(a1*a2);
         
         
      case 'RS05_RS05'     % Rupp and Selker, 2005 (early-time, b=3)
                           % Rupp and Selker, 2005 (late-time, b=f(n))
         
         n        = bfra_conversions(b2,'b','n','isflat',true);         
         fR1      = bfra_specialfunctions('fR1',n);
         fR2      = bfra_specialfunctions('fR2',n);
         
         n1       = n+1;
         n2       = n+2;
         n3       = 1/(n+3);
         c1c2     = ((fR1*fR2^n2/(2^n*n1))^n3)/(D*A);
         a1a2     = (a1*a2^(n+2))^(1/(n+3));
         
      case 'PK62_BS04'      % Polubarinova-Kochina, 1962 (early-time, b=3)
                           % Boussinesq, 1904 (late-time, b=1.5)

         c1c2  = (1.133^(1/3))/D * (4.804^(2/3))/A;
         a1a2  = a1^(1/3)*a2^(2/3);
         
      case 'PK62_BS03'        % Polubarinova-Kochina, 1962 (early-time)
                              % Boussinesq, 1903 (late-time)
         p     = 1/3;
         c1c2  = sqrt(1.133*p)*pi/(D*A);
         a1a2  = sqrt(a1*a2);

   end

   % no square roots are taken, but this must hold to restrict phi to 0-1
   if c1c2 > a1a2
      warning('phi=%.2f',c1c2/a1a2)
   end
   
   phi(m) = c1c2/a1a2;
   if dispfit == true
      fprintf([soln ', phi = %.3f\n'],phi(m))
   end
end

end

function [soln,desc,b2]  = parsesolutions(soln1,soln2,b2,isflat);
   
   % option to get all solutions
   if strcmp(soln1,'all') && strcmp(soln2,'all')
      [soln,desc] = allcombos();
      return;
   end
   
   % early time
   switch soln1
      case 'Polubarinova-Kochina, 1962'
         soln1 = 'PK62';
      case 'Rupp and Selker, 2005'
         soln1 = 'RS05';
      case 'Brutsaert, 1994'
         soln1 = 'BR94';
   end

   % late time
   switch soln2
      case 'Boussinesq, 1904 b=3/2'
         soln2 = 'BS04';
      case 'Rupp and Selker, 2005 b=f(n)'
         soln2 = 'RS05';
      case 'Boussinesq, 1903 b=1'
         soln2 = 'BS03';
      case 'Rupp and Selker, 2006 b=1'
         soln2 = 'RS06b1';
      case 'Rupp and Selker, 2006 b=f(n)'
         soln2 = 'RS06';
   end
   
   
   % not sure if we want this
   if b2 < 1
      b2 = 1;
   end
   
   if isflat == true

      % late-time RS05 is valid for 1.5 <= b < 2, but the solution appears
      % valid for 1<b<2, except that 1<b<1.5 corresponds to an inverted
      % water table
      % if strcmp(soln2,'RS05') && (b2 < 3/2 || b2>=2)
      if strcmp(soln2,'RS05') && (b2 <= 1 || b2>=2)
         warning('Requested late-time solution (Rupp and Selker, 2005) is incompatible with b<1.5 or b>=2, using Boussinesq, 1903, b=1')
         soln2  = 'BS03';
         
      % late-time B04 has b = 3/2
      elseif strcmp(soln2,'BS04') && (b2 ~= 3/2)
         warning('Requested late-time solution (Boussinesq, 1904) implies b=3/2, using b=3/2')
         b2 = 3/2;
         
      % late-time B03 has b = 1
      elseif strcmp(soln2,'BS03') && (b2 ~= 1)
         warning('Requested late-time solution (Boussinesq, 1903) implies b=1, using b=1')
         b2 = 1;
      end
      
   else

      if strcmp(soln1,'RS05') && (b2 < 3/2 || b2>=2)
         warning('Requested late-time solution (Rupp and Selker, 2005) is incompatible with b<1.5 or b>=2, using Boussinesq, 1903, b=1')
         soln2  = 'B03';
         
      elseif strcmp(soln2,'BS04') && (b2 ~= 3/2)
         warning('Requested late-time solution (Boussinesq, 1904) implies b=3/2, using b=3/2')
         b2 = 3/2;
         
      elseif strcmp(soln2,'BS03') && (b2 ~= 1)
         warning('Requested late-time solution (Boussinesq, 1903) implies b=1, using b=1')
         b2 = 1;
      end
      
   end

   % concatenate the early-time and late-time solution
   soln  = strcat(soln1,['_' soln2]);
   
   switch soln
      case 'PK62_BS04'
         desc = {'early: PK62, flat + constant k(z) + nonlinear';'late: BS04, flat + constant k(z) + nonlinear'};
      case 'PK62_BS03'
         desc = {'early: PK62, flat + constant k(z) + nonlinear';'late: BS03, flat + constant k(z) + linearized'};
      case 'PK62_RS05'
         desc = {'early: PK62, flat + constant k(z) + nonlinear';'late: RS05, flat + k(z)=(Z/D)^n + nonlinear'};
      case 'RS05_RS05'
         desc = {'early: RS05, flat + k(z)=(Z/D)^n + nonlinear';'late: RS05, flat + k(z)=(Z/D)^n + nonlinear'};
      case 'BR94_BR94'
         desc = {'early: BR94, sloped + constant k(z) + linearized';'late: BR94, sloped + constant k(z) + linearized'};         
      case 'BR94_RS06'      
         desc = {'early: BR94, sloped + constant k(z) + linearized';'late: RS06, sloped + k(z)=(Z/D)^n + nonlinear'};
      case 'BR94_RS06b1'      
         desc = {'early: BR94, sloped + constant k(z) + linearized';'late: RS06b1, sloped + constant k(z) + nonlinear'};
      case 'BR94_BS04'
         desc = {'early: BR94, sloped + constant k(z) + linearized';'late: BS04, flat + constant k(z) + nonlinear'};
      case 'BR94_BS03'
         desc = {'early: BR94, sloped + constant k(z) + linearized';'late: BS03, flat + constant k(z) + linearized'};
      case 'BR94_RS05'
         desc = {'early: BR94, sloped + constant k(z) + linearized';'late: RS05, flat + k(z)=(Z/D)^n + nonlinear'};
   end
   
   soln = cellstr(soln);
  
   
   
end
   
function [combos,descriptions] = allcombos()
   % in summary, all possible combos:
earlysolns  = {'PK62','PK62','PK62','RS05','BR94','BR94','BR94','BR94','BR94','BR94'};
latesolns   = {'BS04','BS03','RS05','RS05','BR94','RS06','RS06b1','BS04','BS03','RS05'};
descriptions= {'flat + constant k(z) + nonlinear early, flat + constant k(z) + nonlinear late', ...
               'flat + constant k(z) + nonlinear early, flat + constant k(z) + linearized late', ...
               'flat + constant k(z) + nonlinear early, flat + k(z)=(Z/D)^n + nonlinear late',...
               'flat + k(z)=(Z/D)^n + nonlinear early, flat + k(z)=(Z/D)^n + nonlinear late', ...
               'sloped + constant k(z) + linearized early, sloped + constant k(z) + linearized late', ...
               'sloped + constant k(z) + linearized early, sloped + k(z)=(Z/D)^n + nonlinear late', ...
               'sloped + constant k(z) + linearized early, sloped + constant k(z) + nonlinear late', ...
               'sloped + constant k(z) + linearized early, flat + constant k(z) + nonlinear late', ...
               'sloped + constant k(z) + linearized early, flat + constant k(z) + linearized late', ...
               'sloped + constant k(z) + linearized early, flat + k(z)=(Z/D)^n + nonlinear late'};
            
combos = cell(10,1); 
for n = 1:numel(earlysolns)
   combos{n} = [earlysolns{n} '_' latesolns{n}];
end

% note that at early time, the solutions do not depend on k(z) (b=3 for all
% solutions used here), so it would seem appropriate to use a constant k(z)
% solution for early time and non-constant at late time. Also, as flow
% progresses, the influence of slope diminishes, and the effective
% catchment may very well be the lowest-slope, effectively flat areas, so
% it would also seem appropriate to use sloped solution for early time and
% flat for late. HOWEVER, I have not verified the validity of all possible
% combinations and there are surely mathematical incompatibilities.

% % THIS IS A BETTER WAY BUT NOT IMPLEMENTED
% % define:
% % flat         = 0, sloped       = 1
% % constant kz  = 0, non-constnat = 1,
% % linearized   = 0, nonlinear    = 1
% % we have:
% modelstruct = [   0,0,1,0,0,1;
%                   0,0,1,0,0,0;
%                   0,0,1,0,1,1;
%                   0,1,1,0,1,1;
%                   1,0,1,1,0,0;
%                   1,0,1,1,1,1;
%                   1,0,1,1,0,1;
%                   1,0,1,0,0,1;
%                   1,0,1,0,0,0;
%                   1,0,1,0,1,1    ];
% % could use this to build the 'descriptions'                
% modopts     = {'flat','sloped';'k(z)=c','k(z)=(Z/D)^n';'linearized','nonlinear'};

% can't use this becaue we don't want all combos
% slope          = {'flat','sloped'};
% conductivity   = {'k(z)=c','k(z)=(Z/D)^n'};
% solutiontype   = {'linearized','nonlinear'};
% ensemble       = ensembleList(slope,conductivity,solutiontype);

% % started to build this 
% for n = 1:size(modopts,1)*2
%    for m = 1:size(modelopts,2)
%       switch m
%          case 0
%             modopt = 'flat ';
%          case 1
%       end
%    end
% end
end
   
   
   
   