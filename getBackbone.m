function [bbSubs, len, bbImg]=getBackbone(img2,debugFlag)
% [bbSubs, len, bbImg]=getBackbone(img)
% bbSubs: subs [row col] for backbone pixels in connection order, which is good for tracing.
% len: backbone length.
% img2: binary image skeleton matrix. There should not be loop in the
% skeleton. skeleton pixel is 1.
% Output bbImg: logcial image containing only the longest path.

global img imgWidth imgHeight diagonalDis;

if nargin==1
	debugFlag=0;
end

diagonalDis=sqrt(2);

img2=img2~=0;
img=img2;
%	nif debugFlag || outputImgFlag
%		img2=img2~=0;
%	else
%		clear img2;
%	end

imgWidth=size(img,2);
imgHeight=size(img,1);

%% The first phase: find an end point.
% Algorithm: find a non-zero pixel, and trace to an end point by erasing
% along the search route.
sp=find(img,1);
[sp(1) sp(2)]=ind2sub(size(img),sp);
nbr1=nbr8(sp);
img(sp(1),sp(2))=0;
if size(nbr1,1)~=1 % sp now is not an end point.
    while(nbr1(1)~=0)
        sp=nbr1(1,:);
        % There could be a dead loop if Ren-shape is here.
        %     fprintf(1,'Now sp goes to %f\t%f\n',sp(1),sp(2));
        nbr1=nbr8(sp);
        img(sp(1),sp(2))=0;
    end
end

%% Tracing.

% Restore img.
img=img2;
img(sp(1),sp(2))=0;

% img(oldPoint(1),oldPoint(2))=1;
% img(sp(1),sp(2))=0; % The start point is visited and filled.

vNum=1;
vertices(vNum,:)=[vNum,sp(1),sp(2)];
% vertices: label, row, col.
% edges: label1, label2, len.

[nbr1 isNbr4]=nbr8(sp);
if isNbr4
	firstLen=1;
else
	firstLen=diagonalDis;
end
% start vertices queue. [startPointLabel row col firstLen].
svQueue(1,:)=[vNum, nbr1, firstLen];
img(nbr1(1),nbr1(2))=0;
eNum=0;
queIdx=1;
edges=zeros(1,3);
while (queIdx<=size(svQueue,1))
	[ep len]=traceToEJ(svQueue(queIdx,2:3),svQueue(queIdx,4));
    
    % Debug.
    if (ep(2)==274)
        fprintf(1,'Now the 274.\n');
    end
	
	if (vertices((vertices(:,2)==ep(1)),3)==ep(2))
		fprintf(1,'Same vertex label???!!!\n');
		idx=find(vertices(:,2)==ep(1));
		fprintf(1,'vertex: %d\t%d\t%d\n',vertices(idx,1),vertices(idx,2),vertices(idx,3));
		fprintf(1,'ep: %d\t%d\n', ep(1), ep(2));
	end
	
	vNum=vNum+1;
	vertices(vNum,:)=[vNum ep(1) ep(2)];
	eNum=eNum+1;
	edges(eNum,:)=[svQueue(queIdx,1) vNum len];
	queIdx=queIdx+1;
%	 ep=int32(ep); % make sure the image index are int32 not double.
% 	nbr1=nbr8(ep);
% 	img(ep(1),ep(2))=0;

	[nbr1 isNbr4]=nbr8(ep);
	if nbr1(1)==0 % The last unfilled pixel.
%		 break;
		continue;
	end

	for k=1:size(nbr1,1)
		if isNbr4(k)
			firstLen=1;
		else
			firstLen=diagonalDis;
		end
		svQueue(size(svQueue,1)+1,:)=[vNum nbr1(k,:) firstLen];
        img(nbr1(k,1),nbr1(k,2))=0;
	end
end

%% Find the backbone from distance matrix.
%% Warshall algorithm.

% disp('Debug');

% Construct adjacency matrix.
l=size(vertices,1);
A=inf(l,l);
for i=1:size(edges,1)
	idx1=edges(i,1);
	idx2=edges(i,2);
	A(idx1,idx2)=edges(i,3);
	A(idx2,idx1)=edges(i,3);
end
% Diagonal are zeros.
for i=1:size(A,1)
    A(i,i)=0;
end

D=fastFloyd(A);

[Y I]=max(D(:));
len=Y;
[row col]=ind2sub(size(D),I);
sp=vertices(row,2:3);
% ep=vertices(col,2:3);

img=img2;
clear img2;
for i=1:size(vertices,1)
	if i==row || i==col
		continue;
	end
	nbrs=nbr8(vertices(i,2:3));
	if size(nbrs,1)==1
        img(vertices(i,2),vertices(i,3))=0;
		ep=traceToEJ(vertices(i,2:3),0);
		img(ep(1),ep(2))=1;
	end
end
bbImg=img;
if debugFlag
	imshow(bbImg);
end

% Get the backbone indices sequence.
% Now img is the backbone img.
bbSubs=getBbSub(sp);

end

function bbSubs=getBbSub(sp)
% Get the backbone pixel subcripts from start point.
% Now img is the backbone img.
global img;

bbSubs=zeros(2,2);
img(sp(1),sp(2))=0;
len=1;
bbSubs(len,:)=sp;
nbr1=nbr8(sp);
while nbr1(1)~=0
    if size(nbr1,1)~=1
    % When Ren-shape joint is met, first trace to its 4-nbr, then 8-nbr.
%         fprintf(1,'Error: There are %d nbrs at sp
%         %d\t%d.\n',size(nbr1,1),sp(1),sp(2));
        nbr1=nbr1(1,:);
    end

	img(nbr1(1),nbr1(2))=0;
	len=len+1;
	bbSubs(len,:)=nbr1;
%     sp=nbr1;
	nbr1=nbr8(nbr1);
end

end

function [ep len]=traceToEJ(sp,len)
% [ep len]=traceToEJ(sp,len)
% Input 'len' is the previous length. The output 'len' will add up on the
% input 'len'.
% Trace the skeleton to an end point or a junction.

global img diagonalDis;

[nbr1 isNbr4]=nbr8(sp);
% img(sp(1),sp(2))=0; % Sp should be 0 before tracing, after it's put into svQueue.
% In case the input sp is an ep.
ep=sp;
% len=0;

while (size(nbr1,1)==1 && nbr1(1)~=0) || size(nbr1,1)==2 % normal point will have 1 8-nbr since the previous one is filled!
	% nbr1 has 2-rows indicates there may be a Ren-shape and the present pos is
	% (1,2) or (2,3).
	%1  @
	%2  @@
	%3 @
	
	if size(nbr1,1)==2 && abs(nbr1(1,1)-nbr1(2,1))+abs(nbr1(1,2)-nbr1(2,2))==1
		% nbr1(1,:) is the 4-nbr.
		len=len+1;
		img(nbr1(1,1),nbr1(1,2))=0; % this is center of Ren-shape.
		ep=nbr1(1,:);
%		 [nbr1 isNbr4]=nbr8(nbr1);
		break;
	end
	
	if size(nbr1,1)==2 && abs(nbr1(1,1)-nbr1(2,1))+abs(nbr1(1,2)-nbr1(2,2))~=1;
		% A joint is met.
		%1 @ @
		%2  @
		%3 @
		break;
	end
	
	if isNbr4
		len=len+1;
	else
		len=len+diagonalDis;
	end
	img(nbr1(1),nbr1(2))=0;
	ep=nbr1;
	[nbr1 isNbr4]=nbr8(nbr1);
end

% In case the input sp is an ep.
img(ep(1),ep(2))=0;

% End of traceToEJ
end

function [nbrs isNbr4]=nbr8(p)
% Find neighbours clockwise.
% nbrs: [row col]. isNbr4 is ture if the nbrs is a 4-nbr.
% NOTE: 4-nbrs are always ahead of other 8-nbrs in nbrs, which is good for tracing Ren-shape.
% Return [0 0] and isNbr4=2 if no nbr is found.
global img;

len=0;
px=p(2); % col
py=p(1); % row
nbrs=[0 0];
isNbr4=2;
% 4-way nbrs.
nbrsIdx4=[py-1 px; py px+1; py+1 px; py px-1];
% Other 8-nbrs except 4-nbrs.
nbrsIdx8=[py-1 px+1; py+1 px+1; py+1 px-1; py-1 px-1];
nbrsIdx4=cleanNbrs(nbrsIdx4);
nbrsIdx8=cleanNbrs(nbrsIdx8);
% [py-1 px; py-1 px+1; py px+1; py+1 px+1; py+1 px; py+1 px-1; py px-1; py-1 px-1];

for i=1:size(nbrsIdx4,1)
	if img(nbrsIdx4(i,1),nbrsIdx4(i,2))
		len=len+1;
		nbrs(len,:)=nbrsIdx4(i,:);
		isNbr4(len)=1;
	end
end

for i=1:size(nbrsIdx8,1)
	if img(nbrsIdx8(i,1),nbrsIdx8(i,2))
		len=len+1;
		nbrs(len,:)=nbrsIdx8(i,:);
		isNbr4(len)=0;
	end
end

% End of nbr.
end

%%
% End of getBackbone.

function nbrsIdx=cleanNbrs(nbrsIdx)
% Clean all nbrs with illegal subcripts such as 0 or out of border.

global imgWidth imgHeight;

nbrsIdx((nbrsIdx(:,1)==0),1)=0;
nbrsIdx((nbrsIdx(:,1)>imgHeight),1)=0;
nbrsIdx((nbrsIdx(:,1)==0),2)=0;
nbrsIdx((nbrsIdx(:,1)>imgHeight),2)=0;

nbrsIdx((nbrsIdx(:,2)==0),1)=0;
nbrsIdx((nbrsIdx(:,2)>imgWidth),1)=0;
nbrsIdx((nbrsIdx(:,2)==0),2)=0;
nbrsIdx((nbrsIdx(:,2)>imgWidth),2)=0;

nbrsIdx=nbrsIdx(nbrsIdx>0);
nbrsIdx=reshape(nbrsIdx,length(nbrsIdx)/2,2);
end

