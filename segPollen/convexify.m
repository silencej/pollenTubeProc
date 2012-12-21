function pskel=convexify(pskel)
% Trace the parsimonious skeleton, break the contour at the joint and inflection points, so that each segment is either concave upwards or downwards.
% Input pskel must be a parsimonious skeleton binary image, with skel pixels being TRUE.
%
% Copyright: 2012, Chaofeng Wang, PICB, owen263@gmail.com.

% Window length for the direction accumulator.
wlen=5;

global gImg;

[rowNum colNum]=size(pskel);

% vis: log for pixels to be visited.
% Only those 1-pixels in pskel need to visit.
vis=pskel;
% Start point queue.
spQueue=zeros(100,2);
% Visiting pointer to traverse the spQueue.
spqPt=1;
% Direction accumulator.
% The elements here correspond to the count of each direction, from North to NorthWest clockwise.
da=zeros(8,1);

[row col]=find(vis,1);
while ~row
nbrs=nbr8([row col]);

end

end
