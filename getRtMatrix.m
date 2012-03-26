function [fVec fnames rtMatrix startPoints newSkel bubbles tips lbbImg]=getRtMatrix(skelImg,somabw,branchThre,distImg,grayOri,bw)
% Get the feature matix, the row is observation and col is variable.
% fVec: feature vector.
% fnames: feature names.

global handles;

debugFlag=1;

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

% if nargout>=2
%     debugFlag=1;
% end

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

bubblesPt=0;
bubbles=zeros(30,3); % [row col radius].
tipsPt=0;
tips=zeros(20,3); % [row col width].
newSkel=zeros(size(skelImg));
lbbLen=0;
lbbImg=[];
lbbSubs=[];

for i=1:num
    
    % If the skelImg is too small, ignore it.
    skelNumThre=10;
    if length(find(L==i,skelNumThre))<skelNumThre
        continue;
    end
    
    qImg=(L==i)&pImg;
    [startPoints(i,1) startPoints(i,2)]=find(qImg,1);
    clear qImg;
    
    %     if debugFlag
    [subMatrix labelNum skelPart bubblesPart tipsPart lbbImg2 lbbLen2 lbbSubs2]=decomposeSkel(L==i,startPoints(i,:),labelNum,branchThre,distImg,maxBblNum);
    if lbbLen2>lbbLen
        lbbImg=lbbImg2;
        lbbLen=lbbLen2;
        lbbSubs=lbbSubs2;
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
%     else
%         [subMatrix labelNum]=decomposeSkel(L==i,startPoints(i,:),labelNum,branchThre,distImg,maxBblNum);
%     end

    contentLen=size(subMatrix,1);
    if ~contentLen
        continue;
    end
    
	rtMatrix(contentPt+1:contentPt+contentLen,:)=subMatrix;
    contentPt=contentPt+contentLen;
end

% if debugFlag
bubbles=bubbles(bubbles(:,1)~=0,:);
tips=tips(tips(:,1)~=0,:);
% end

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

%% Cal all features.

% fVec=zeros(1,length(fnames)); % It is a row vector.

% Expand rtMatrix to 6 cols if ~widthFlag. Then it will be reverted before
% it's returned.
if ~widthFlag
    tempRtMat=rtMatrix;
    rtMatrix=[rtMatrix zeros(size(rtMatrix,1),2)];
end

psArea=sum(sum(somabw));
bbLen=lbbLen;
bbId=rtMatrix(1,2); % The backbone branch id. bbIdx=1.
bbChildNum=sum(rtMatrix(:,1)==bbId);
flBrNum=sum(rtMatrix(:,1)==0);
sbIdx=find(rtMatrix(:,1)==bbId,1); % The second backbone row index.
if isempty(sbIdx)
    sbPos=0;
    sbLen=0;
    sbWidth=0;
    sbTipWidth=0;
else
    sbPos=rtMatrix(sbIdx,3);
    sbLen=rtMatrix(sbIdx,4);
    sbWidth=rtMatrix(sbIdx,5);
    sbTipWidth=rtMatrix(sbIdx,6);
end
bbWidth=rtMatrix(1,5);
bbTipWidth=rtMatrix(1,6);
bubbleNum=size(bubbles,1);
if ~bubbleNum
    lbRad=0;
else
    lbRad=max(bubbles(:,3));
end

% fVec(13)=fVec(8)/fVec(7);
widthRatio=bbTipWidth/bbWidth;
bbInt=double(grayOri(lbbSubs));
bbIntStd=std(bbInt(:));
somaIntAvg=sum(sum(uint8(somabw).*grayOri))/sum(sum(somabw)); % Soma/grain intensity average.
nonSomabw=bw-(bw&somabw);
brIntAvg=sum(sum(uint8(nonSomabw).*grayOri))/sum(sum(nonSomabw)); % Other intensity average.
avgIntRatio=brIntAvg/somaIntAvg;

%% Wavy feature.
% If the lbbLen is too short, then no smooth and no wavy is calculated.
% waveCoef=sum(|dev|)/lbbLen.
% wavyNum=number of significant peaks.
if lbbLen<=450
    wavyCoef=0;
    wavyNum=0;
else
    x=lbbSubs(:,2);
    y=lbbSubs(:,1);
    addpath('smooth_contours');
    r=201;
    [xs,ys]=smooth_contours(x,y,r);
    % Although the signs are not used in wavyCoef, but it may be useful
    % later as to obtain the wavy frequency.
    % Compare original contours point with smoothed contour point.
    % npiv: Nearest point index vec, without the edges.
	[dev npiv]=nearestPoc([x y],[xs ys],handles.scale); % Nearest point on curve.
	if isempty(dev)
		error('Curve too short to do nearestPoc.');
	end

	%% TODO: make smooth_contour smooth the edges either.

    % First cmp y, then cmp x, if contour>sContour, then the sign is +,
    % else -.
%    dev=euDist([y x],[ys xs]); % Deviation from the center line.
%    signs=sign(y-ys);
	signs=sign(y-ys(npiv));
%    xd=x-xs;
    xd=x-xs(npiv);
    signs(signs==0)=sign(xd(signs==0));
    dev=dev.*signs;
    wavyCoef=sum(abs(dev))/lbbLen;
	sWin=20; % Smooth window.
	sWin=sWin*handles.scale/20;
    [pks,locs]=findpeaks(filtfilt(dev,1/sWin*ones(sWin,1),1));
    wavyPkThre=5; % Default ther in 20X scale.
    wavyPkThre=wavyPkThre*handles.scale/20;
    wavyNum=length(find(pks>wavyPkThre));
    if debugFlag
        pLocs=find(pks>wavyPkThre);
        figure('name','Wavy Points Picked'),plot(x,y,'-k');
        hold on;
        plot(xs,ys);
        plot(x(locs(pLocs)),y(locs(pLocs)),'or');
        plot(xs(npiv(locs(pLocs))),ys(npiv(locs(pLocs))),'.r');
    end
end

%% Make fVec.
% bb, backbone, is the longest backbone starting from soma/pollen.
% psArea: pollen/soma area in pixel.
% flBrNum: first level branch number. First-level branches start from
% soma/pollen.
% bbChildNum: the number of child branches on the bb, not all.
% sb: longest second level branch on the bb.
% lbRad: largest bubble radius.
% widthRatio: bbTipWidth/bbWidth.
% bbIntStd: backbone path intensity std.
% avgIntRatio: mean(branches intensities)/mean(soma/grain intensities).
fnames={'psArea', 'bbLen', 'bbChildNum', 'flBrNum', 'sbPos', ...
    'sbLen','bbWidth', 'bbTipWidth', 'sbWidth', 'sbTipWidth', ...
    'bubbleNum', 'lbRad','widthRatio','bbIntStd','avgIntRatio','wavyCoef','wavyNum'};
% psArea bbLen bbChildNum flBrNum sbPos sbLen bbWidth bbTipWidth sbWidth sbTipWidth bubbleNum lbRad].

fVec=[psArea, bbLen, bbChildNum, flBrNum, sbPos, ...
    sbLen, bbWidth, bbTipWidth, sbWidth, sbTipWidth, ...
    bubbleNum, lbRad, widthRatio, bbIntStd, avgIntRatio,wavyCoef,wavyNum];

% Re-scale if the scale is not 40.
if floor(handles.scale)~=handles.defaultScale
    sf=handles.defaultScale/handles.scale;
    fVec(1)=fVec(1)*(sf^2); % area is sf^2 scaled.
    fVec(2)=fVec(2)*sf;
    fVec(6:10)=fVec(6:10).*sf;
    fVec(12)=fVec(12)*sf;
end

% for i=1:length(fnames)
%     eval(['fVec(i)=' fnames{i}]);
% end


% end.
if ~widthFlag
    rtMatrix=tempRtMat;
end

end
