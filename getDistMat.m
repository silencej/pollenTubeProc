function [A vertices skelImg]=getDistMat(skelImg,shortLenThre,startPoint)
% This function is used to get the Distance Matrix between each joint/end
% point. "skelImg" must be parsiSkel bitwise image with only 1 connected
% component!
% "vertices": [vertexNum row col epFlag shortEpFlag adLen]. 'epFlag'
% denotes whether the vertex is an end point. 'shortEpFlag' denotes whether
% the vertex is a short branch end point. 'adLen' is the edge length, used to sort short branches, adLen=0 if
% the vertex is an adjoint point.
% "A": adjacency matrix. "D": distance matrix.
% Output "skelImg" is the new skel with short branches cut off.

% Set debugFlag to 1 if you have doubt in the correctness of 'getDistMat'.
debugFlag=0;

vertices=findVertices(skelImg,shortLenThre);

% Plot.
if debugFlag
    l=size(vertices,1);
    fprintf(1,'getDistMat: the debugFlag is on, so plot output are produced.\n');
    figure, imshow(skelImg);
    hold on;
    for i=1:l
        if vertices(i,4) % long end points.
            plot(vertices(i,3),vertices(i,2),'og');
        else % joint points.
            plot(vertices(i,3),vertices(i,2),'.g');
        end
    end
end

% Cut short end points from skelImg, while keep startPoint.
skelImg=cutSep(skelImg,vertices,shortLenThre,startPoint);
[vertices edges]=findVertices(skelImg,shortLenThre);

if debugFlag
    l=size(vertices,1);
    for i=1:l
        if vertices(i,4) % long end points.
            plot(vertices(i,3),vertices(i,2),'or');
        else % joint points.
            plot(vertices(i,3),vertices(i,2),'.r');
        end
    end
    hold off;
end

if isempty(vertices)
    A=[];
    return;
end

% Warshall algorithm.
% D=fastFloyd(A);


%% Construct adjacency matrix.
l=size(vertices,1);
A=inf(l,l);
for i=1:size(edges,1)
	idx1=find(vertices(:,1)==edges(i,1));
    if isempty(idx1)
        continue;
    end
	idx2=find(vertices(:,1)==edges(i,2));
    if isempty(idx2)
        continue;
    end
	A(idx1,idx2)=edges(i,3);
	A(idx2,idx1)=edges(i,3);
end

% Diagonal are zeros.
for i=1:size(A,1)
	A(i,i)=0;
end

end

function skel=cutSep(skel,vertices,shortLenThre,startPoint)
% Cut the short branches from skel image in increasing length order,
% and keep the short branches if it is not a short branch any more in the process.
% Example:
% 1
% 2  @
% 3  @
% 4  @@@@@@...
% 5 @
%
% The pixel (5,1) (4,2) will be erased first, and then the branch starting
% at (2,2) is not a short branch any more.
%
% Whether or not the joint point should be kept depends on the resulted
% connecteness.

global gImg;
gImg=skel;

sepVers=vertices(vertices(:,5)~=0,:); % sep points.
% No SEP.
if isempty(sepVers)
    return;
end
[sv idx]=sort(sepVers(:,6));
sprintf(num2str(sv(1)));
sepVers=sepVers(idx,:); % sorted.
for i=1:size(sepVers,1)
    % Keep the startPoint.
    if euDist(startPoint,sepVers(i,2:3))<sqrt(2)*2
        continue;
    end
    oldImg=gImg;
    [ep len]=traceToEJ(sepVers(i,2:3),0);
    if len>shortLenThre
        gImg=oldImg; % Put it back.
    else
        [L num]=bwlabel(gImg,8);
        sprintf(num2str(L(1)));
        if num>=2
            gImg(ep(1),ep(2))=1; % Put back joint point.
        end
    end
end

skel=gImg;

end

function [vertices edges]=findVertices(skelImg,shortLenThre)

global gImg;

gImg=skelImg;

diagonalDis=sqrt(2);

% tempImg=gImg;

%find an end point.
sp=findEndPoint(gImg);
if isempty(sp)
    vertices=[];
    edges=[];
    return;
end

% Tracing.
vNum=1;
vertices(vNum,:)=[vNum,sp(1),sp(2),1,0,0]; % [vertexNum, row, col, epFlag, shortEpFlag, adLen].
startEpFlag=1;

% edges: label1, label2, len.

% start vertices queue: svQueue. [startPointLabel row col firstLen].
% startPoint can be any end point or neighbours of joint point. Thus we
% need initial len in traceToEJ.
svQueue(1,:)=[vNum, sp, 0];

eNum=0;
queIdx=1;
edges=zeros(1,3);
while (queIdx<=size(svQueue,1))
	[ep len isEp]=traceToEJ(svQueue(queIdx,2:3),svQueue(queIdx,4));
    % If there is only one point in the img, traceToEJ will be stay still.
    if len==0
%         D=0;
        vertices=[0 ep(1) ep(2) 1 1];
        return;
    end
    
	if (vertices((vertices(:,2)==ep(1)),3)==ep(2))
		fprintf(1,'Same vertex label???!!!\n');
		idx=find(vertices(:,2)==ep(1));
		fprintf(1,'vertex. row: %d\t col: %d\t len: %d\n',vertices(idx,1),vertices(idx,2),vertices(idx,3));
		fprintf(1,'ep. row: %d\t col: %d\n', ep(1), ep(2));
		error('getBb: Error.');
	end
	
    % NOTE: There may exist short branches, which can cause trouble in geting the nearest
    % end point beside pollenPos, so we clear them here.
    % NOTE: the short edge may exist between joint points. So we first
    % check if ep is an end point.
    
    % If the start end point is a short branch end point, then flag its
    % shortness.
    if startEpFlag
        vertices(1,6)=len;
    end
    if startEpFlag && len<shortLenThre
        vertices(1,5)=1;
    end
    % Set startEpFlag to 0.
    startEpFlag=0;
    
    shortEpFlag=0;
    adLen=0;
    if isEp
        adLen=len;
    end
    if isEp && len<shortLenThre
        shortEpFlag=1;
    end

	vNum=vNum+1;
	vertices(vNum,:)=[vNum ep(1) ep(2) isEp shortEpFlag adLen];
	eNum=eNum+1;
	edges(eNum,:)=[svQueue(queIdx,1) vNum len];
	queIdx=queIdx+1;

% 	[nbr1 isNbr4]=nbr8(ep);
% 	if nbr1(1)==0 % ep is and end point.
    if isEp
		continue;
    end

    % Add ep nbrs into svQueue.
    [nbr1 isNbr4]=nbr8(ep);
	for k=1:size(nbr1,1)
		if isNbr4(k)
			firstLen=1;
		else
			firstLen=diagonalDis;
		end
		svQueue(size(svQueue,1)+1,:)=[vNum nbr1(k,:) firstLen];
		gImg(nbr1(k,1),nbr1(k,2))=0;
	end
end

end

