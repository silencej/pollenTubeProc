function [bbSubs, bbLen, bbImg]=getLongestPath(skelImg)
% "getLongestPath" is used to get the longest path from a connected skeleton bw image.
% It's used to get the backbone of whole image, and also the third branch
% in remainder image. The third branch is the longest path in the remainder
% image though.
% As in getLongestBranch, "bbSubs" is well ordered, e.g. starting at the
% joint branching point.

global gImg;

if isempty(find(skelImg,1))
	error('Error: The skelImg is all black!');
end

[D vertices]=getDistMat(skelImg);

% If D==0, which means there is only one point in skelImg.
if length(D)==1
	bbSubs=vertices(1,2:3);
	bbLen=1;
	bbImg=skelImg;
	return;
end

[Y I]=max(D(:));
bbLen=Y;
[row col]=ind2sub(size(D),I);
sp=vertices(row,2:3);
ep=vertices(col,2:3);

gImg=skelImg;

for i=1:size(vertices,1)
	if i==row || i==col
		continue;
	end
	nbrs=nbr8(vertices(i,2:3));
	if nbrs(1)~=0
		tempImg=gImg; % Backup gImg.
%		 img(vertices(i,2),vertices(i,3))=0;
		epTrace=traceToEJ(vertices(i,2:3),0);
		gImg(epTrace(1),epTrace(2))=1; % Need to keep the ep.
		if size(nbrs,1)==1 % If it's end point, no connectness check is needed.
			continue;
		end
		% If backbone's two end points is not connected, reverse the
		% erasing.
		L=bwlabel(gImg,8);
		if L(sp(1),sp(2))~=L(ep(1),ep(2))
			gImg=tempImg; % restore gImg.
		end
	end
end
bbImg=gImg;

% Get the backbone indices sequence.
% Now img is the backbone img.
bbSubs=getPathSubs(sp);

% Re-order the tbSubs to make it start with joint branching point.
gImg=skelImg;
nbrs=nbr8(bbSubs(1,:));
if size(nbrs,1)==1
	bbSubs=bbSubs(end:-1:1,:);
end

end

%%%%%

function subs=getPathSubs(sp)
% Get the path pixel subcripts from start point.
% subs: subs [row col] for backbone pixels in connection order, which is good for tracing.
% Now gImg is the backbone img.
global gImg;

subs=zeros(2,2);
gImg(sp(1),sp(2))=0;
len=1;
subs(len,:)=sp;
nbr1=nbr8(sp);
while nbr1(1)~=0
	if size(nbr1,1)~=1
	% When Ren-shape joint is met, first trace to its 4-nbr, then 8-nbr.
%		 fprintf(1,'Error: There are %d nbrs at sp
%		 %d\t%d.\n',size(nbr1,1),sp(1),sp(2));
		nbr1=nbr1(1,:);
	end

	gImg(nbr1(1),nbr1(2))=0;
	len=len+1;
	subs(len,:)=nbr1;
%	 sp=nbr1;
	nbr1=nbr8(nbr1);
end

end

