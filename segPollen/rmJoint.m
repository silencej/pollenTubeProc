function pskel=rmJoint(pskel)
% Trace the parsimonious skeleton, break all the joint points.
% Input pskel must be a parsimonious skeleton binary image, with skel pixels being TRUE.
%
% Copyright: 2012, Chaofeng Wang, PICB, owen263@gmail.com.

global gImg;

gImg=pskel;
% vis=pskel;

[row col]=find(pskel);
for i=1:length(row)
%     vis(row(i),col(i))=0;
    if ~gImg(row(i),col(i))
        continue;
    end
    [nbrs isNbr4]=nbr8([row(i) col(i)]);
    if size(nbrs,1)==3
        if isNbr4(1)
            gImg(nbrs(1,1),nbrs(1,2))=0;
        end
        gImg(row(i),col(i))=0;
    end
    if size(nbrs,1)==4
        gImg(row(i),col(i))=0;
%         gImg(row-2:row+2,col-2:col+2)
%         disp('Error: windhole appears!');
    end
%     [row col]=find(vis,1);
% Ren-shape: rm the center pixel plus one 4-nbr.
%  @
%  @@
% @
% Common joint: just rm the center pixel.
% @ @
%  @
% @
% Windhole
% Case 1: it could not exist since each branch having a common joint
% which will be trimmed.
%  @
% @ @
%  @
% Case 2:  just remove center pixels.
% @ @
%  @
% @ @
end

pskel=gImg;

end