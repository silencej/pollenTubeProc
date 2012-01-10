function [backbone, branches]=decomposeSkel(skelImg,pollenPos,branchThre,debugFlag)
% Decompose the parsi skel into backbone, and then significant branches.
% "skelImg": binary image skeleton matrix. There should not be loop in the skeleton. skeleton pixel is 1.
% "branchThre" is used so only long enough branches in skel are got.
% And, the branch should contact the backbone. Branch of branch is ignored.
% "backbone" is structure: subs,len,bw.
% "branches" is array of structure: subs,len,img,ratio,bbbIdx. Use branches(i).subs to access.
% If there is no long branches, "branches" is an empty struct.
% subs: [row col] for backbone pixels in connection order, which is good for tracing.
% len: backbone length.
% img: logcial image containing only the longest path.
% ratio is the length ratio of the third branch joint at the backbone from the start point of parent subs. Simply, it's the relative branching position.
% bbbIdx is the backbone branching index in backbone subs.

global gImg;

if nargin<4
	debugFlag=0;
end

% skelImg=skelImg~=0;
% img=img2;

%% Get backbone.
% Get the longest path passing pollenPos from a connected skeleton bw image.
[bbSubs, bbLen, bbImg]=getBackbone(skelImg,pollenPos);
backbone.subs=bbSubs;
backbone.len=bbLen;
backbone.img=bbImg;

if debugFlag
	imshow(bbImg);
end

%% Third branch.
% Definition: the longest path in the skel-backbone image.

branches=struct('');

remImg=skelImg-bbImg; % Remaining img.
if isempty(find(remImg,1))
%     error('remImg is empty!');
    return;
end
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
    if isempty(find(tempImg,1))
        break;
    end
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
% Cal the ratio of branching point in parent subs.
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


