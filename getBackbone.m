function [bbSubs, bbLen, bbImg, tbSubs, tbLen, tbImg, ratioInBbSubs, idxLen]=getBackbone(img2,debugFlag)
% [bbSubs, bbLen, bbImg, tbSubs, tbLen, tbImg, ratioInBbSubs, idxLen]=getBackbone(img)
% bbSubs: subs [row col] for backbone pixels in connection order, which is good for tracing.
% len: backbone length.
% img2: binary image skeleton matrix. There should not be loop in the
% skeleton. skeleton pixel is 1.
% Output bbImg: logcial image containing only the longest path.
% tbSubs, tbLen, tbImg are all third branch things.
% ratioInBbSubs is the length ratio of the third branch joint at the backbone from the
% start point of bbSubs. Simply, it's the relative branching position.
% idxLen is the branching point index in bbSubs.

global gImg diagonalDis;

if nargin==1
	debugFlag=0;
end

diagonalDis=sqrt(2);

img2=img2~=0;
img=img2;

% Get backbone.
% getBb is used to get the longest path from a connected skeleton bw image.
[bbSubs, bbLen, bbImg]=getBb;

if debugFlag
	imshow(bbImg);
end

%% Third branch.
% Definition: the longest path in the skel-backbone image.

remImg=img2-bbImg; % Remaining img.
tempImg=keepLargest(remImg,8);
img=tempImg;
[tbSubs, tbLen, tbImg]=getBb;

% Cal the ratio of tb in bbSubs.
img=tbImg;
sp=findEndpoint(img);
gImg=img;
ep=traceToEJ(sp);
nbrs=nbr8(ep);
% The backbone returned by getBb may contain Ren-shape. So the following.
while nbrs(1)
	ep=traceToEJ(nbrs);
	nbrs=nbr8(ep);
end

%-- For classic 4-loop-in-skel.
% if ep(1)==2520 && ep(2)==1727
%	 hold off;
%	 disp();
% end

if ep(1)==3579 && ep(2)==862
	hold off;
	imshow(bbImg);
	figure;
	imshow(img2);
end

% tbImg=tempImg-img;
% img=tbImg;
% tbSubs=getBbSub(sp);

bbSp=bbSubs(1,:);
img=img2;
nbrs=nbr8(sp);
if size(nbrs,1)==1 % sp is end point.
	% Below can cause error if the thirdBranch is only one point, which is possible.
%	 nbrs=nbr8(ep);
%	 if size(nbrs,1)==1
%		 fprintf(1,'getBackbone: tb ratio can''t cal! ep and sp both end points.\n');
%		 ratioInBbSubs=0;
%		 return;
%	 end
	img=bbImg;
	[len idxLen]=getLenOnLine(bbSp,ep); % tb Joint Point is ep.
elseif size(nbrs,1)>1
	img=bbImg;
	[len idxLen]=getLenOnLine(bbSp,sp); % tb Joint Point is sp now.
else
	fprintf(1,'getBackbone: Don''t know what happend.\n');
	ratioInBbSubs=0;
	return;
end
ratioInBbSubs=len/bbLen;

% %% Get the longest branch which has an end not belonging to the backbone.
% % [Y I]=max(A(:));
% % len=Y;
% % [row col]=ind2sub(size(D),I);
% % sp=vertices(row,2:3);
% 
% tbLen=0;
% tbSubs=0;
% for i=1:size(vertices,1)
% 	if i==row || i==col
% 		continue;
% 	end
% 	nbrs=nbr8(vertices(i,2:3));
% 	if size(nbrs,1)==1 % This is an end point.
%		 [tbLen mIdx]=max(A(vertices(i,1),:));
%		 img(vertices(i,2),vertices(i,3))=0;
% 		ep=traceToEJ(vertices(i,2:3),0);
% 		img(ep(1),ep(2))=1;
% 	end
% end

end


function [len idxLen]=getLenOnLine(sp,ep)
% sp is the first point on the backbone.
% sp must be an end point!
% ep may not reside on the line but contact it instead.
global img diagonalDis;

idxLen=1; % idxLen is used to plot the branch position on the bbProfile, it's different from euclidean len.
[nbrs isNbr4]=nbr8(sp);
img(sp(1),sp(2))=0;
if isNbr4
	len=1;
else
	len=diagonalDis;
end
dis=abs(ep(1)-nbrs(1))+abs(ep(2)-nbrs(2));

% This is a classic 4-loop-in-skel problem. Hope it's rare!
% if ep(1)==2520 && ep(2)==1727
%	 disp();
% end

% while dis>2
% dis>3, for the classic 4-loop-in-skel problem.
while dis>3
	sp=nbrs(1,:); % Backbone img may have Ren-shape joint!
	[nbrs isNbr4]=nbr8(sp);
	if nbrs(1)==0
		fprintf(1,'Sp: %d %d. Ep: %d %d.\n',sp(1),sp(2),ep(1),ep(2));
		imwrite(img,'getLenOnLineError.png','png');
		error('getLenOnLine: Traced to the end point, No contact?\n');
	end
	img(sp(1),sp(2))=0;
	idxLen=idxLen+1;
	if isNbr4
		len=len+1;
	else
		len=len+diagonalDis;
	end
	dis=abs(ep(1)-sp(1))+abs(ep(2)-sp(2));
end

end



