function [subMatrix labelNum]=decomposeSkel(skelImg,startPoint,labelNum,widthFlag,branchThre)
% Decompose the parsi skel.
% "labelNum", as input is the present used label number, and the new label should start at labelNum+1.
% Then return the used largest "labelNum".
% "skelImg": binary image skeleton matrix. There should not be loop in the skeleton. skeleton pixel is 1.
%
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

% global gImg;

% if nargin<4
% 	debugFlag=0;
% end

fprintf(1,'widthFlag is %d.\n', widthFlag);

% "vertices": [vertexNum row col epFlag shortEpFlag].
[A vertices]=getDistMat(skelImg,branchThre,startPoint);

% If the skelImg has only a short branch and is deleted in 'getDistMat',
% subMatrix is empty.
if isempty(A)
    subMatrix=[];
    return;
end

% % If A==0, which means there is only one point in skelImg.
% if length(A)==1
% %	bbSubs=vertices(1,2:3);
% %	bbLen=1;
% %	bbImg=skelImg;
% 	error('length(A)==1, there is only one point in skelImg!');
% end

% Find the startPoint in vertices.
% For 'spIdx=i', the A returned by getDistMat is in the same order as vertices, so A(i,j)
% is the adjacent distance of vertices(i) and vertices(j).
minDist=inf;
spIdx=0;
for i=1:size(vertices,1)
    dist=abs(vertices(i,2)-startPoint(1))+abs(vertices(i,3)-startPoint(2));
	if dist<minDist
% 		spIdx=vertices(i,1);
        spIdx=i; % see preceding comment.
        minDist=dist;
	end
end

subMatrix=inf(20,5);
contentPt=1; % Content point in subMatrix.
pt=1; % Visiting pointer on subMatrix.

D=fastFloyd(A);
[Y I]=max(D(:,spIdx));
bbLen=Y;
% sp=vertices(spIdx,2:3);
% ep=vertices(I,2:3);
labelNum=labelNum+1;
% The branch starting at soma is default to be: brDist=0.
subMatrix(1,:)=[spIdx 0 labelNum 0 bbLen]; % Now [spIdx parentLabel label brDist bbLen]. Later on "spIdx" will be erased.
innerVertices=findInnerVers(A,spIdx,I);
if ~isempty(innerVertices)
    len=length(innerVertices);
	brDistVec=zeros(len,1);
    for i=1:len
        brDistVec(i)=D(spIdx,innerVertices(i));
    end
    % Now the "bbLen" is 0 and needs to be filled in later on.
	subMatrix(contentPt+1:contentPt+len,:)=[innerVertices labelNum*ones(len,1) (labelNum+1:labelNum+len)' brDistVec zeros(len,1)];
    contentPt=contentPt+len;
	labelNum=labelNum+len;

	% Let the inner vertices not adjacent to each others.
	for i=1:len-1
		A(innerVertices(i),innerVertices(i+1))=inf;
		A(innerVertices(i+1),innerVertices(i))=inf;
	end
end

% Let the sp and ep points not adjacent to all others.
A(I,:)=inf;
A(:,I)=inf;
A(spIdx,:)=inf;
A(:,spIdx)=inf;

while pt<contentPt
	pt=pt+1;
	spIdx=subMatrix(pt,1);
	D=fastFloyd(A);
	D(D==inf)=0; % Make all inf entries be 0 so max will not find on them.
	[Y I]=max(D(:,spIdx));
	bbLen=Y;
%	sp=vertices(spIdx,2:3);
%	ep=vertices(I,2:3);
%	labelNum=labelNum+1;
%	subMatrix(end+1,:)=[0 labelNum 0 bbLen]; % [parentLabel label brDist bbLen].

	subMatrix(pt,end)=bbLen;
	innerVertices=findInnerVers(A,spIdx,I);
	if ~isempty(innerVertices)
        len=length(innerVertices);
        brDistVec=zeros(len,1);
        for i=1:len
            brDistVec(i)=D(spIdx,innerVertices(i));
        end
        % Now the "bbLen" is 0 and needs to be filled in later on.
		subMatrix(contentPt+1:contentPt+len,:)=[innerVertices labelNum*ones(len,1) (labelNum+1:labelNum+len)' brDistVec zeros(len,1)];
        contentPt=contentPt+len;
        labelNum=labelNum+len;

		% Let the inner vertices not adjacent to each others.
		for i=1:length(innerVertices)-1
			A(innerVertices(i),innerVertices(i+1))=inf;
			A(innerVertices(i+1),innerVertices(i))=inf;
		end
	end

	% Let the sp and ep points not adjacent to all others.
	A(I,:)=inf;
	A(:,I)=inf;
	A(spIdx,:)=inf;
	A(:,spIdx)=inf;

end

% Erase the "spIdx" column from subMatrix.
subMatrix=subMatrix(:,2:end);
% Erase all inf rows.
subMatrix=subMatrix(subMatrix(:,1)~=inf,:);

end
