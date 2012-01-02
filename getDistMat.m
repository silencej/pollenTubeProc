function [D vertices]=getDistMat(skelImg)
% This function is used to get the Distance Matrix between each joint/end point.
% "skelImg" must be parsiSkel bitwise image with only 1 connected component!

global gImg diagonalDis;

gImg=skelImg;
clear skelImg;

tempImg=gImg;

%% The first phase.

%find an end point.
sp=findEndPoint(gImg);

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
		D=0;
		vertices=[0 ep(1) ep(2)];
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

%% Warshall algorithm.

D=fastFloyd(A);

end

