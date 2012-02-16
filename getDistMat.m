function [A vertices]=getDistMat(skelImg)
% This function is used to get the Distance Matrix between each joint/end
% point. "skelImg" must be parsiSkel bitwise image with only 1 connected
% component!
% "vertices": [vertexNum row col epFlag shortEpFlag]. 'epFlag'
% denotes whether the vertex is an end point. 'shortEpFlag' denotes whether
% the vertex is a short branch end point.
% "A": adjacency matrix. "D": distance matrix.

global gImg;

% Leave off all branches shorter than 10 diagnal pixels: ceil(10*sqrt(2)).
shortLenThre=15;

gImg=skelImg;
clear skelImg;

diagonalDis=sqrt(2);

% tempImg=gImg;

%% The first phase.

%find an end point.
sp=findEndPoint(gImg);

% Tracing.
vNum=1;
vertices(vNum,:)=[vNum,sp(1),sp(2),1,0]; % [vertexNum, row, col, epFlag, shortEpFlag].
startEpFlag=1;

% edges: label1, label2, len.

% start vertices queue. [startPointLabel row col firstLen].
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
        D=0;
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
    if startEpFlag && len<shortLenThre
        vertices(1,5)=1;
    end
    shortEpFlag=0;
    if isEp && len<shortLenThre
        shortEpFlag=1;
    end

	vNum=vNum+1;
	vertices(vNum,:)=[vNum ep(1) ep(2) isEp shortEpFlag];
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

%% Construct adjacency matrix.
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


% Warshall algorithm.
% D=fastFloyd(A);

end

