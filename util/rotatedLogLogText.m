function rotatedLogLogText(xtxt,ytxt,txt,slope,axpos)

%    https://stackoverflow.com/questions/52928360/rotating-text-onto-a-line-on-a-log-scale-in-matplotlib
   
   % to add text, need the slope in figure space
   xlims    = xlim;
   ylims    = ylim;
   xfactor  = axpos(1)/(log10(xlims(2))-log10(xlims(1)));
   yfactor  = axpos(2)/(log10(ylims(2))-log10(ylims(1)));   % slope adjustment
   atxt     = slope*atand(yfactor/xfactor);           % adjust angle
   
   text(  xtxt,ytxt,txt,                   ...
         'HorizontalAlignment','center',     ...
         'VerticalAlignment', 'bottom',      ...
         'FontSize',12,                      ...
         'rotation',atxt, ...
         'Interpreter','latex')
end