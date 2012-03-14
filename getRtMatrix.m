function [fVec rtMatrix startPoints newSkel bubbles tips lbbImg]=getRtMatrix(skelImg,somabw,branchThre,distImg)
% Get the feature matix, the row is observation and col is variable.

if nargin<4
%     widthFlag=0; % The default option is to process neurons, thus no width info.
    distImg=[];
end
if isempty(distImg)
    widthFlag=0;
else
    widthFlag=1;
end

if isempty(find(skelImg,1))
	error('Error: The skelImg is all black!');
end

debugFlag=0;
if nargout>=2
    debugFlag=1;
end

maxBblNum=5;

% Find the start points. dilate(somabw)-somabw could give you candidates.
dsomabw=imdilate(somabw,strel('disk',1));
% NOTE: bwmorph to complete the diag to make 8-connections to
% 4-connections is important.
pImg=(bwmorph(dsomabw-somabw,'diag')).*skelImg; % Point image.

if ~sum(sum(pImg))
    figure,imshow(skelImg|somabw);
    error('The skeleton doesnot touch somabw. There may be improper annotations.');
end

%% Cal rtMatrix.

% The skelImg is broken into parts by somabw.
skelImg=skelImg.*(~somabw);
[L num]=bwlabel(skelImg,8);
labelNum=0; % labelNum is the present occupied label number. The new branch should start its label as labelNum+1.

if ~widthFlag
    rtMatrix=inf(50,4);
    % [parentId, id, branchPos, length].
else
    rtMatrix=inf(50,6+maxBblNum*2);
    % [parentId, id, branchPos, length, bbWidth, tipWidth, bubbles...].
end


contentPt=0;
startPoints=zeros(num,2);

if debugFlag
    bubblesPt=0;
    bubbles=zeros(30,3); % [row col radius].
    tipsPt=0;
    tips=zeros(20,3); % [row col width].
    newSkel=zeros(size(skelImg));
    lbbLen=0;
    lbbImg=[];
end

for i=1:num
    
    % If the skelImg is too small, ignore it.
    skelNumThre=10;
    if length(find(L==i,skelNumThre))<skelNumThre
        continue;
    end
    
    qImg=(L==i)&pImg;
    [startPoints(i,1) startPoints(i,2)]=find(qImg,1);
    clear qImg;

    if debugFlag
        [subMatrix labelNum skelPart bubblesPart tipsPart lbbImg2 lbbLen2]=decomposeSkel(L==i,startPoints(i,:),labelNum,branchThre,distImg,maxBblNum);
        if lbbLen2>lbbLen
            lbbImg=lbbImg2;
            lbbLen=lbbLen2;
        end
        if ~isempty(bubblesPart)
            bblNum=size(bubblesPart,1);
            bubbles(bubblesPt+1:bubblesPt+bblNum,:)=bubblesPart;
            bubblesPt=bubblesPt+bblNum;
        end
        if ~isempty(tipsPart)
            tipsNum=size(tipsPart,1);
            tips(tipsPt+1:tipsPt+tipsNum,:)=tipsPart;
            tipsPt=tipsPt+tipsNum;
        end
        newSkel=skelPart | newSkel;
    else
        [subMatrix labelNum]=decomposeSkel(L==i,startPoints(i,:),labelNum,branchThre,distImg,maxBblNum);
    end

    contentLen=size(subMatrix,1);
    if ~contentLen
        continue;
    end
    
	rtMatrix(contentPt+1:contentPt+contentLen,:)=subMatrix;
    contentPt=contentPt+contentLen;
end

if debugFlag
    bubbles=bubbles(bubbles(:,1)~=0,:);
    tips=tips(tips(:,1)~=0,:);
end

% Clean inf rows.
rtMatrix=rtMatrix(rtMatrix(:,1)~=inf,:);

if find(rtMatrix(:)==inf)
    error('Inf entry in rtMatrix! Now widthFlag is 0, so this should not happen!');
end

% Shrink trailing 0 cols out.
colNum=size(rtMatrix,2);
for i=colNum:-1:1
    if isempty(find(rtMatrix(:,i)~=0,1))
        rtMatrix=rtMatrix(:,1:end-1);
    else
        break;
    end
end

% Re-labling and Rearranging.

% Re-label the branches so they are in length order. The less label, the longer the branch.
% Exchange the label if the longer soma branch has larger label.
% Re-labe only the soma branches.
tempMatrix=rtMatrix;
sbIdx=find(~tempMatrix(:,1));
sbLen=tempMatrix(sbIdx,4);
sbLabel=tempMatrix(sbIdx,2);
[sbLabelS,si]=sort(sbLabel,'ascend');
sbLen2=sbLen(si);
[sv,si]=sort(sbLen2,'descend');
sprintf(num2str(sv));
for i=1:length(sbIdx)
	if si(i)~=i
%		rtMatrix=tempMatrix(tempMatrix(:,1)==tempMatrix(sbIdx(mi),2));
		rtMatrix((tempMatrix(:,1)==sbLabelS(si(i))),1)=sbLabelS(i);
		rtMatrix((tempMatrix(:,2)==sbLabelS(si(i))),2)=sbLabelS(i);
	end
end

% Re-label the branches in length order rather than position order.
% NOTE: you can comment this part out if you want the alignment in position
% order instead of length order.
tempMatrix=rtMatrix;
parentIds=tempMatrix(:,2);
parentIds=parentIds(parentIds~=0);
visitedPids=[];
for i=1:length(parentIds)
    if ~isempty(find(visitedPids==parentIds(i),1))
        continue;
    end
    partIdx=find(tempMatrix(:,1)==parentIds(i));
    childLen=tempMatrix(partIdx,4);
    childIds=tempMatrix(partIdx,2);
    [childIdsS,si]=sort(childIds,'ascend');
    childLen2=childLen(si);
    [sv,si]=sort(childLen2,'descend');
    sprintf(num2str(sv));
    for j=1:length(partIdx)
        if si(j)~=j
            rtMatrix((tempMatrix(:,1)==childIdsS(si(j))),1)=childIdsS(j);
            rtMatrix((tempMatrix(:,2)==childIdsS(si(j))),2)=childIdsS(j);
        end
    end
end

% Rearrange.
% The sort in matlab keeps the previous order in the case of equal numbers.
% First sort the childIds, then parentIds.
[v,si]=sort(rtMatrix(:,2),'ascend');
sprintf(num2str(v(1)));
rtMatrix=rtMatrix(si,:);
[v,si]=sort(rtMatrix(:,1),'ascend');
sprintf(num2str(v(1)));
rtMatrix=rtMatrix(si,:);

%% Make fVec.
% bb, backbone, is the longest backbone starting from soma/pollen.
% psArea: pollen/soma area in pixel.
% flBrNum: first level branch number. First-level branches start from
% soma/pollen.
% bbChildNum: the number of child branches on the bb, not all.
% sb: longest second level branch on the bb.
% lbRad: largest bubble radius.
% [psArea bbLen bbChildNum flBrNum sbPos sbLen bbWidth bbTipWidth sbWidth sbTipWidth bubbleNum lbRad].
fVec=zeros(1,12); % It is a row vector.

% psArea.
fVec(1:2)=[sum(sum(somabw)) lbbLen];
bbId=rtMatrix(1,2); % The backbone branch id. bbIdx=1.
fVec(3)=sum(rtMatrix(:,1)==bbId);
fVec(4)=sum(rtMatrix(:,1)==0);
sbIdx=find(rtMatrix(:,1)==bbId,1); % The second backbone row index.
if isempty(sbIdx)
    fVec(5:6)=[0 0];
    fVec(9:10)=[0 0];
else
    fVec(5)=rtMatrix(sbIdx,3);
    fVec(6)=rtMatrix(sbIdx,4);
    fVec(9:10)=rtMatrix(sbIdx,5:6);
end
fVec(7:8)=rtMatrix(1,5:6);
fVec(11)=size(bubbles,1);
if ~fVec(11)
    fVec(12)=0;
else
    fVec(12)=max(bubbles(:,3));
end
end
