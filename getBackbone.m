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

global img diagonalDis;

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
sp=findEndpoint;
ep=traceToEJ(sp);
nbrs=nbr8(ep);
% The backbone returned by getBb may contain Ren-shape. So the following.
while nbrs(1)
    ep=traceToEJ(nbrs);
    nbrs=nbr8(ep);
end

%-- For classic 4-loop-in-skel.
% if ep(1)==2520 && ep(2)==1727
%     hold off;
%     disp();
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
%     nbrs=nbr8(ep);
%     if size(nbrs,1)==1
%         fprintf(1,'getBackbone: tb ratio can''t cal! ep and sp both end points.\n');
%         ratioInBbSubs=0;
%         return;
%     end
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
%         [tbLen mIdx]=max(A(vertices(i,1),:));
%         img(vertices(i,2),vertices(i,3))=0;
% 		ep=traceToEJ(vertices(i,2:3),0);
% 		img(ep(1),ep(2))=1;
% 	end
% end

end

function [bbSubs, bbLen, bbImg]=getBb
% getBb is used to get the longest path from a connected skeleton bw image.
% It's used to get the backbone of whole image, and also the third branch
% in remainder image. The third branch is the longest path in the remainder
% image though.
% The global img must be parsiSkel bw image before calling the function!

global img diagonalDis;

tempImg=img;

%% The first phase.

%find an end point.
sp=findEndpoint;

% Tracing.

vNum=1;
vertices(vNum,:)=[vNum,sp(1),sp(2)];

% vertices: label, row, col.
% edges: label1, label2, len.

% [nbr1 isNbr4]=nbr8(sp);
% if isNbr4
% 	firstLen=1;
% else
% 	firstLen=diagonalDis;
% end

% start vertices queue. [startPointLabel row col firstLen].
% startPoint can be any end point or neighbours of joint point. Thus we
% need initial len in traceToEJ.
svQueue(1,:)=[vNum, sp, 0];

eNum=0;
queIdx=1;
edges=zeros(1,3);
while (queIdx<=size(svQueue,1))
	[ep len]=traceToEJ(svQueue(queIdx,2:3),svQueue(queIdx,4));
    % If there is only one point in the img, traceToEJ will be stay still.
    if len==0
        bbSubs=ep;
        bbLen=1;
        bbImg=tempImg;
        return;
    end
    
	if (vertices((vertices(:,2)==ep(1)),3)==ep(2))
		fprintf(1,'Same vertex label???!!!\n');
		idx=find(vertices(:,2)==ep(1));
		fprintf(1,'vertex. row: %d\t col: %d\t len: %d\n',vertices(idx,1),vertices(idx,2),vertices(idx,3));
		fprintf(1,'ep. row: %d\t col: %d\n', ep(1), ep(2));
        error('getBb: Error.');
	end
	
	vNum=vNum+1;
	vertices(vNum,:)=[vNum ep(1) ep(2)];
	eNum=eNum+1;
	edges(eNum,:)=[svQueue(queIdx,1) vNum len];
	queIdx=queIdx+1;

	[nbr1 isNbr4]=nbr8(ep);
	if nbr1(1)==0 % The last unfilled pixel.
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

% Warshall algorithm.

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
bbLen=Y;
[row col]=ind2sub(size(D),I);
sp=vertices(row,2:3);
ep=vertices(col,2:3);

img=tempImg;
for i=1:size(vertices,1)
	if i==row || i==col
		continue;
	end
	nbrs=nbr8(vertices(i,2:3));
	if nbrs(1)~=0
        tempImg=img; % restore img.
%         img(vertices(i,2),vertices(i,3))=0;
        epTrace=traceToEJ(vertices(i,2:3),0);
		img(epTrace(1),epTrace(2))=1; % Need to keep the ep.
        if size(nbrs,1)==1 % If it's end point, no connectness check is needed.
            continue;
        end
        % If backbone's two end points is not connected, reverse the
        % erasing.
        L=bwlabel(img,8);
        if L(sp(1),sp(2))~=L(ep(1),ep(2))
            img=tempImg;
        end
	end
end
bbImg=img;

% Get the backbone indices sequence.
% Now img is the backbone img.
bbSubs=getBbSub(sp);

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
%     disp();
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

function sp=findEndpoint
% Algorithm: find a non-zero pixel, and trace to an end point by erasing
% along the search route.
% The function will write on global img, but will restore it at the end.
global img;

tempImg=img;

sp=find(img,1);
[sp(1) sp(2)]=ind2sub(size(img),sp);
nbr1=nbr8(sp);
img(sp(1),sp(2))=0;
if size(nbr1,1)~=1 % sp now is not an end point.
    while(nbr1(1)~=0)
        sp=nbr1(1,:);
%         if sp(1)==813
%             disp('here!');
%         end
%         fprintf(1,'sp: %d %d\n',sp(1),sp(2));
        % There could be a dead loop if Ren-shape is here. To solve this,
        % nbr8 will first return 4-nbrs before 8-nbrs.
        %     fprintf(1,'Now sp goes to %f\t%f\n',sp(1),sp(2));
        nbr1=nbr8(sp);
        img(sp(1),sp(2))=0;
    end
end

img=tempImg;
end

function bbSubs=getBbSub(sp)
% Get the backbone pixel subcripts from start point.
% bbSubs: subs [row col] for backbone pixels in connection order, which is good for tracing.
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
% input 'len'. 'len' defaults to 0.
% Trace the skeleton to an end point or a junction. Tracing starts from sp, and erases every pixel along the path, including sp and ep.

if nargin<2
    len=0;% len=0;
end

global img diagonalDis;

[nbr1 isNbr4]=nbr8(sp);
img(sp(1),sp(2))=0;
% In case the input sp is an ep.
ep=sp; % If sp is an isolated point, ep=sp.

while (size(nbr1,1)==1 && nbr1(1)~=0) || size(nbr1,1)==2 % normal point will have 1 8-nbr since the previous one is filled!
	% nbr1 has 2-rows indicates there may be a Ren-shape (i.e. the present pos is
	% (1,2) or (2,3) at below. The pos can't be (2,2) if input sp is surely
	% an end point.), or a joint.
	%1  @
	%2  @@
	%3 @
	
    % Ren Shape. The first 4-nbr will be the ep.
    if size(nbr1,1)==2 && abs(nbr1(1,1)-nbr1(2,1))+abs(nbr1(1,2)-nbr1(2,2))==1
        % nbr1(1,:) is the 4-nbr.
        len=len+1;
        img(nbr1(1,1),nbr1(1,2))=0; % this is center of Ren-shape.
        ep=nbr1(1,:);
        %		 [nbr1 isNbr4]=nbr8(nbr1);
        break;
    end

    % Joint. ep=previous one.
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
% 4-way nbrs. Order: N, E, S, W.
nbrsIdx4=[py-1 px; py px+1; py+1 px; py px-1];
% Other 8-nbrs except 4-nbrs. Order: NE, SE, SW, NW.
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

global img;

imgWidth=size(img,2);
imgHeight=size(img,1);

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

