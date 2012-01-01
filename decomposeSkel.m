function [backbone, branches]=decomposeSkel(skelImg,pollenPos,branchThre,debugFlag)
% Decompose the parsi skel into backbone, and then significant branches.
% "skelImg": binary image skeleton matrix. There should not be loop in the skeleton. skeleton pixel is 1.
% "branchThre" is used so only long enough branches in skel are got.
% And, the branch should contact the backbone. Branch of branch is ignored.
% "backbone" is structure: subs,len,bw.
% "branches" is array of structure: subs,len,img,ratio,bbbIdx. Use branches(i).subs to access.
% subs: [row col] for backbone pixels in connection order, which is good for tracing.
% len: backbone length.
% img: logcial image containing only the longest path.
% ratio is the length ratio of the third branch joint at the backbone from the start point of parent subs. Simply, it's the relative branching position.
% bbbIdx is the backbone branching index in backbone subs.

global gImg diagonalDis;

if nargin<3
	debugFlag=0;
end

diagonalDis=sqrt(2);

skelImg=skelImg~=0;
% img=img2;

%% Get backbone.
% Get the longest path passing pollenPos from a connected skeleton bw image.
[bbSubs, bbLen, bbImg]=getLongestBranch(skelImg,pollenPos);
backbone.subs=bbSubs;
backbone.len=bbLen;
backbone.img=bbImg;

if debugFlag
	imshow(bbImg);
end

%% Third branch.
% Definition: the longest path in the skel-backbone image.

remImg=skelImg-bbImg; % Remaining img.
tempImg=keepLargest(remImg,8);
% img=tempImg;
[tbSubs, tbLen, tbImg]=getLongestPath(tempImg);
branchNum=0;
if tbLen>branchThre
	branchNum=branchNum+1;
	[ratio,bbbIdx]=getRatio(skelImg,backbone,tbImg);
	branches(branchNum).subs=tbSubs;
	branches(branchNum).len=tbLen;
	branches(branchNum).img=tbImg;
	branches(branchNum).ratio=ratio;
	branches(branchNum).bbbIdx=bbbIdx;
end
while tbLen>branchThre
	remImg=remImg-tbImg;
	tempImg=keepLargest(remImg,8);
	[tbSubs, tbLen, tbImg]=getLongestPath(tempImg);
	% Check if the branch is connected to backbone.
	tempImg=tbImg+bbImg;
	[L num]=bwlabel(tempImg,8);
	if num>1
		continue;
	end

	if tbLen>branchThre
		branchNum=branchNum+1;
		[ratio,bbbIdx]=getRatio(skelImg,backbone,tbImg);
		branches(branchNum).subs=tbSubs;
		branches(branchNum).len=tbLen;
		branches(branchNum).img=tbImg;
		branches(branchNum).ratio=ratio;
		branches(branchNum).bbbIdx=bbbIdx;
	end
end

end

%%%%%%%% Sub functions. %%%%%%%%%%%%%%

function [ratio,bbbIdx]=getRatio(skelImg,backbone,tbImg)
% Cal the ratio of tb in parent subs.
% "skelImg" is the whole parsi skel bw image.
% "bbbIdx" is the backbone branching index.

global gImg;

bbImg=backbone.img;
bbSubs=backbone.subs;
bbLen=backbone.len;
clear backbone;

% img=tbImg;
gImg=tbImg;
sp=findEndPoint(gImg);
gImg=tbImg;
ep=traceToEJ(sp);
nbrs=nbr8(ep);
% The tb-backbone returned by getBb may contain Ren-shape. So the following.
while nbrs(1)
	ep=traceToEJ(nbrs);
	nbrs=nbr8(ep);
end

%-- For classic 4-loop-in-skel.
% if ep(1)==2520 && ep(2)==1727
%	 hold off;
%	 disp();
% end

% if ep(1)==3579 && ep(2)==862
% 	hold off;
% 	imshow(bbImg);
% 	figure;
% 	imshow(img2);
% end

bbSp=bbSubs(1,:);
gImg=skelImg;
nbrs=nbr8(sp);
if size(nbrs,1)==1 % sp is end point.
	% Below can cause error if the thirdBranch is only one point, which is possible.
%	 nbrs=nbr8(ep);
%	 if size(nbrs,1)==1
%		 fprintf(1,'getBackbone: tb ratio can''t cal! ep and sp both end points.\n');
%		 ratioInBbSubs=0;
%		 return;
%	 end
	gImg=bbImg;
	[len bbbIdx]=getLenOnLine(bbSp,ep); % tb Joint Point is ep.
elseif size(nbrs,1)>1
	gImg=bbImg;
	[len bbbIdx]=getLenOnLine(bbSp,sp); % tb Joint Point is sp now.
else
	fprintf(1,'getBackbone: Don''t know what happend.\n');
	ratio=0;
	return;
end
ratio=len/bbLen;

end

%%

function [len idxLen]=getLenOnLine(sp,ep)
% sp is the first point on the backbone.
% sp must be an end point!
% ep may not reside on the line but contact it instead.
global gImg diagonalDis;

idxLen=1; % idxLen is used to plot the branch position on the bbProfile, it's different from euclidean len.
[nbrs isNbr4]=nbr8(sp);
gImg(sp(1),sp(2))=0;
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
		imwrite(gImg,'getLenOnLineError.png','png');
		error('getLenOnLine: Traced to the end point, No contact?\n');
	end
	gImg(sp(1),sp(2))=0;
	idxLen=idxLen+1;
	if isNbr4
		len=len+1;
	else
		len=len+diagonalDis;
	end
	dis=abs(ep(1)-sp(1))+abs(ep(2)-sp(2));
end

end



