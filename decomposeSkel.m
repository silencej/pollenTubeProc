function [subMatrix labelNum skelImg bubbles]=decomposeSkel(skelImg,startPoint,labelNum,branchThre,distImg,maxBblNum)
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
%
% NOTE: If distImg is empty, then widthFlag=0.

global gImg;

if nargout>=2
    debugFlag=1;
else
    debugFlag=0;
end

widthFlag=1;
if isempty(distImg)
    widthFlag=0;
end

% if debugFlag && widthFlag
%     fprintf(1,'decomposeSkel.m debugFlag is on, the bubbles plot will show.\n');
% end

% "vertices": [vertexNum row col epFlag shortEpFlag].
[A vertices skelImg]=getDistMat(skelImg,branchThre,startPoint);

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

if ~widthFlag
    subMatrix=inf(30,5); % Now [spIdx parentLabel label brDist bbLen]. Later on "spIdx" will be erased.
else
    subMatrix=inf(30,maxBblNum*2+6); % [spIdx parentLabel label brDist brLen, brWidth firstBubblePos firstBubbleRadius ...].
end

contentPt=1; % Content point in subMatrix.
pt=1; % Visiting pointer on subMatrix.

D=fastFloyd(A);

%% The first run.

[Y I]=max(D(:,spIdx));
bbLen=Y;
% sp=vertices(spIdx,2:3);
% ep=vertices(I,2:3);
labelNum=labelNum+1;

innerVertices=findInnerVers(A,spIdx,I);

if debugFlag && widthFlag
    bubblesPt=0;
    bubbles=zeros(20,3);
else
    bubbles=[];
end

if ~widthFlag
% The branch starting at soma is default to be: brDist=0.
    subMatrix(1,:)=[spIdx 0 labelNum 0 bbLen];
else
    gImg=skelImg;
    [brSubs bbImg]=getBbSubs(vertices,[spIdx; innerVertices; I]); % brSubs starts from the start point of each branch.
    remSkelImg=skelImg-bbImg;
    if debugFlag
        [branchInfo bubblesPart]=traceBranch(brSubs, distImg, bbLen); % bbLen could be left over.
        bblNum=size(bubblesPart,1);
        bubbles(bubblesPt+1:bubblesPt+bblNum,:)=bubblesPart;
        bubblesPt=bubblesPt+bblNum;
        sprintf(num2str(bubblesPt));
    else
        branchInfo=traceBranch(brSubs, distImg, bbLen); % bbLen could be left over.
    end

    biLen=length(branchInfo);
    if biLen>maxBblNum*2+1
%         subMatrix=inf(20,5+length(branchInfo));
        branchInfo=branchInfo(1:maxBblNum*2+1);
    end
    % Padding branchInfo and initialize the pos and rad of bubbles to 0,
    % which is the default way to align empty bubbles.
%     branchInfo=[branchInfo; zeros(maxBblNum*2+1-length(branchInfo),1)];
    tempInfo=zeros(maxBblNum*2+1,1);
    tempInfo(1:biLen)=branchInfo;
    subMatrix(1,:)=[spIdx 0 labelNum 0 bbLen tempInfo']; % brWidth fbPos fbRad sbPos sbRad.
end

if ~isempty(innerVertices)
    len=length(innerVertices);
	brDistVec=zeros(len,1);
    for i=1:len
        brDistVec(i)=D(spIdx,innerVertices(i));
    end
    if ~widthFlag
        % Now the "bbLen" is 0 and needs to be filled in later on.
        subMatrix(contentPt+1:contentPt+len,:)=[innerVertices labelNum*ones(len,1) (labelNum+1:labelNum+len)' brDistVec zeros(len,1)];
    else
        % Now bbLen, branchInfo are all initialized 0 and needs to be
        % filled later on.
        subMatrix(contentPt+1:contentPt+len,:)=[innerVertices labelNum*ones(len,1) (labelNum+1:labelNum+len)' brDistVec zeros(len,maxBblNum*2+2)];
    end
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

%% The other runs.

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

	innerVertices=findInnerVers(A,spIdx,I);
    
    if ~widthFlag
        subMatrix(pt,5)=bbLen;
    else
        gImg=remSkelImg;
        [brSubs bbImg]=getBbSubs(vertices,[spIdx; innerVertices; I]); % brSubs starts from the start point of each branch.
        remSkelImg=remSkelImg-bbImg;
        if debugFlag
            [branchInfo bubblesPart]=traceBranch(brSubs, distImg, bbLen); % bbLen could be left over.
            bblNum=size(bubblesPart,1);
            bubbles(bubblesPt+1:bubblesPt+bblNum,:)=bubblesPart;
            bubblesPt=bubblesPt+bblNum;
            sprintf(num2str(bubblesPt));
        else
            branchInfo=traceBranch(brSubs, distImg, bbLen); % bbLen could be left over.
        end
        biLen=length(branchInfo);
        if biLen>maxBblNum*2+1
            branchInfo=branchInfo(1:maxBblNum*2+1);
        end
        tempInfo=zeros(maxBblNum*2+1,1);
        tempInfo(1:biLen)=branchInfo;
        subMatrix(pt,5:end)=[bbLen tempInfo']; % brWidth fbPos fbRad sbPos sbRad.
    end
    
	if ~isempty(innerVertices)
        len=length(innerVertices);
        brDistVec=zeros(len,1);
        for i=1:len
            brDistVec(i)=D(spIdx,innerVertices(i));
        end
        
        if ~widthFlag
            % Now the "bbLen" is 0 and needs to be filled in later on.
            subMatrix(contentPt+1:contentPt+len,:)=[innerVertices labelNum*ones(len,1) (labelNum+1:labelNum+len)' brDistVec zeros(len,1)];
        else
            % Now bbLen, branchInfo are all initialized 0 and needs to be
            % filled later on.
            subMatrix(contentPt+1:contentPt+len,:)=[innerVertices labelNum*ones(len,1) (labelNum+1:labelNum+len)' brDistVec zeros(len,maxBblNum*2+2)];
        end

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

%% Finish.

% Erase the "spIdx" column from subMatrix.
subMatrix=subMatrix(:,2:end);
% Erase all inf rows.
subMatrix=subMatrix(subMatrix(:,1)~=inf,:);

% if widthFlag
    % NOTE: The shrinking will be done in getRtMatrix.
%     % Shrink trailing inf cols out.
%     colNum=size(subMatrix,2);
%     for i=colNum:-1:1
%         if isempty(find(subMatrix(:,i)~=inf,1))
%             subMatrix=subMatrix(:,1:end-1);
%         else
%             break;
%         end
%     end
    
    % Align the bubbles. Put all the inf entries to 0, which means the
    % missing bubbles are considered as a bubble at 0 pos with 0 radius.
%     subMatrix(subMatrix==inf)=0;
% end

end

function [bbSubs bbImg bbPnum]=getBbSubs(vertices,bbVers)
% bbVers: [si innerVers ei].

global gImg;
% si=bbVers(1);
% ei=bbVers(end);
sp=vertices(bbVers(1),2:3);
ep=vertices(bbVers(end),2:3);

% Sometimes the joint point resides on precedent backbone and is erased in
% remaining skel image. We need them back, otherwise the connectness check
% will not well function since the sp and ep are not connected at the beginning.
gImg(sp(1),sp(2))=1;
gImg(ep(1),ep(2))=1;

% Get the backbone image bbImg, which consists of all vertices in bbVers.

% Put all end points at the beginning so the erasing will start from end
% points first, then joint points become end points and traceToEj could
% perform on them.
epVers=vertices(vertices(:,4)~=0,:);
jpVers=vertices(vertices(:,4)==0,:);
vertices=[epVers; jpVers];

% NOTE: The gImg should be remaining skelImg after previous picking-up. If
% you use the original skelImg to do this, there may be case that the
% branch joint point we want to keep becomes a simple point, and
% traceToEJ will directly pass through it and delete everything. If we use
% the remaining skel, the joint point will always be a joint point or an
% end point, and traceToEJ will recognize them easily.

for i=1:size(vertices,1)
    if ~isempty(find(bbVers==vertices(i,1),1))
        continue;
    end
    %     nbrs=nbr8(vertices(i,2:3));
    
    epTrace=traceToEJ(vertices(i,2:3),0);
    %         epTrace=traceToEJ(nbrs(1,:),0);
    % If backbone's two end points is not connected because of erasing the
    % joint pixel, then restore the joint point.
    L=bwlabel(gImg,8);
    if L(sp(1),sp(2))~=L(ep(1),ep(2)) % Case to keep the joint point.
        gImg(epTrace(1),epTrace(2))=1;
    end
    
end

bbImg=gImg;

% Get subs from the backbone image.

% backbone pixel number, which is always integer, different from bbLen.
bbPnum=length(find(gImg(:)));
bbSubs=zeros(bbPnum,2);
backupImg=gImg;

gImg(sp(1),sp(2))=0;
len=1;
bbSubs(len,:)=sp;
nbr1=nbr8(sp);
while nbr1(1)~=0
    if size(nbr1,1)~=1
        % When Ren-shape joint is met, first trace to its 4-nbr, then 8-nbr.
        nbr1=nbr1(1,:);
    end
    
    gImg(nbr1(1),nbr1(2))=0;
    len=len+1;
    bbSubs(len,:)=nbr1;
    %	 sp=nbr1;
    nbr1=nbr8(nbr1);
end

% Restore the global img.
gImg=backupImg;

% Clean 0 out of bbSubs.
bbSubs=bbSubs(bbSubs(:,1)~=0,:);

if size(bbSubs,1)~=bbPnum
    error('decomposeSkel: bbSubs has different number of entries from bbPnum!!!\n');
end

end
