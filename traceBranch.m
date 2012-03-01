function [branchInfo bubbles]=traceBranch(bbSubs, bbDist, bbLen)
% branchInfo: [bbWidth fbPos fbRad sbPos sbRad...].
% fb: first bubble. sb: second bubble. tb: third bubble...
% Thus, branchInfo would be of length of 1,3,5,7,9,...
% NOTE: the bubbles are sorted in order of radius, not position! So the
% first bubble will always be the largest one.
% fbPos is the ratio position from the beginning of the branch, thus all
% end bubbles' pos is almost 1. 0<fbPos<1. So are all other pos like sbPos
% and tbPos.
% "bubbles": [row col radius]. Used for debugging. If there is no demanding
% on bubbles, then return an empty matrix.

if nargin<3
    bbLen=0;
end
bubbleFlag=1;
if nargout<2
    bubbleFlag=0;
end

% Bubble detection scale thre. Only bubbles with radius>coef*tubeWidth are
% reported.
bubbleRadCoef=2;

% % branchInfo will be initialized a 7-length column vector.
% branchInfo=zeros(7,1);

% bbDist=bbDist(:);
bbProfile=bbDist(sub2ind(size(bbDist),bbSubs(:,1),bbSubs(:,2)));
% The length of the input x must be more than three times the filter
% order in filtfilt.
if length(bbProfile)>3*48
	winLen=48;
else
	winLen=floor(length(bbProfile)/3);
end
bbProfile=double(bbProfile);
bbProfileF=filtfilt(ones(1,winLen)/winLen,1,bbProfile);

% Points largest bbProfiles, circleCenter = [row col distanceTransform].
[pks locs]=findpeaks(bbProfileF);

% Estimate backbone width.
% 1. Ordinary estimate.
% bbWidth=median(bbProfile)+1.4826*mad(bbProfile,1);
% 2. Only use median as an estimate for tube width.
% bbWidth=median(bbProfile);
% 3. Use median of all minima as an estimate for tube width.
[vv]=findpeaks(-bbProfileF);
vv=-vv;
% bbWidth=median(vv)+1.4826*mad(vv);
bbWidth=median(vv);

% % Get rid of all peaks lower than bbWidth.
% locs=locs(pks>bbWidth);
% pks=pks(pks>bbWidth);
% thre=median(pks)+1.4826*mad(pks,1);
% thre=median(bbProfile);
% thre=min(handles.bubbleRadCoef*bbWidth,grain(3));
thre=bubbleRadCoef*bbWidth;
locs=locs(pks>thre);
pks=pks(pks>thre);

% pksS - sorted.
[pksS I]=sort(pks,'descend');
locsS=locs(I);

bubbleNum=length(pksS);
branchInfo=zeros(1+2*bubbleNum,1);
branchInfo(1)=bbWidth;

if bubbleFlag
    bubbles=zeros(bubbleNum,3);
end

for i=1:bubbleNum
%     gImg=bbImg;
%     sp=bbSubs(1,:);
%     bubblePos=bbSubs(locsS(i),:);
%     [len idx]=getLenOnLine(sp,bubblePos);
    len=getEuLen(bbSubs,1,locsS(i));
    if ~bbLen
        bbLen2=getEuLen(bbSubs,1,size(bbSubs,1));
        fprintf(1,'The bbLen is %d and %d, are they same?\n',bbLen,bbLen2);
        bbLen=bbLen2;
    end
%     bubbleNum=bubbleNum+1;
%     branchInfo(bubbleNum*2)=double(len/bbLen);
%     branchInfo(bubbleNum*2+1)=bbProfile(locsS(i));
    branchInfo(i*2)=double(len/bbLen);
    branchInfo(i*2+1)=bbProfile(locsS(i));
    if bubbleFlag
        bubbles(i,:)=[bbSubs(locsS(i),:) bbProfile(locsS(i))];
    end
end

% % Shrink trailing zero cols out.
% ind=find(branchInfo(end:-1:1));
% branchInfo=branchInfo(1:end-ind+1);

if ~bubbleFlag
    bubbles=[];
else

end