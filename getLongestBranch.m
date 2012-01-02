function [bbSubs, bbLen, bbImg]=getLongestBranch(skelImg,pollenPos)
% "getLongestBranch" is used to get the longest path passing the pollenPos, from a connected skeleton bw image.
% It's like "getLongestPath" but there is difference: the path must pass the pollenPos.
% "bbSubs" should start with the end point closest to pollen grain, e.g.,
% bbSubs is ordered.

global gImg;

[D vertices]=getDistMat(skelImg);

% If D==0, which means there is only one point in skelImg.
if length(D)==1
	bbSubs=vertices(1,2:3);
	bbLen=1;
	bbImg=skelImg;
	return;
end

% Find the end point closest to pollenPos.
shortDist=inf;
gImg=skelImg;
epIdx=0;
for i=1:size(vertices,1)
	nbr=nbr8(vertices(i,2:3));
	if size(nbr,1)==1 % end point vertex.
		dist=euDist(vertices(i,2:3),pollenPos);
		if dist<shortDist
			shortDist=dist;
			epIdx=i;
		end
	end
end

if epIdx==0 % If the pollenPos can't specify an end point, the longest path is used.
	[Y I]=max(D(:));
	bbLen=Y;
	[row col]=ind2sub(size(D),I);
	sp=vertices(row,2:3);
	ep=vertices(col,2:3);
else % Choose the longest path passing pollenPos.
	[Y I]=max(D(:,epIdx));
	bbLen=Y;
	sp=vertices(epIdx,2:3); % The sp is the end point closest to pollen grain.
	ep=vertices(I,2:3);
end

%% Get bbImg.
gImg=skelImg;

for i=1:size(vertices,1)
	if i==I || i==epIdx
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
% Since sp is the closest end point to pollen grain, the bbSubs will start
% at the end where pollen grain resides.
bbSubs=getPathSubs(sp);

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

