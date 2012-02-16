function [rtMatrix]=getRtMatrix(skelImg,somabw,branchThre,widthFlag)
% Get the rooted tree matix.
% "rtMatrix", rooted tree matrix. The format is: [parentLabel, label, brDist, bblen].
% Every start point corresponds to a branch (including backbone).

if isempty(find(skelImg,1))
	error('Error: The skelImg is all black!');
end

% Find the start points. dilate(somabw)-somabw could give you candidates.
dsomabw=imdilate(somabw,strel('disk',1));
pImg=(dsomabw-somabw).*skelImg; % Point image.

%% The skelImg is broken into parts by somabw.
skelImg=skelImg.*(~somabw);
[L num]=bwlabel(skelImg,8);
labelNum=0; % labelNum is the present occupied label number. The new branch should start its label as labelNum+1.
rtMatrix=[];
for i=1:num
    [startPoint(1) startPoint(2)]=find((L==i).*pImg,1);
	[subMatrix labelNum]=decomposeSkel(L==i,startPoint,labelNum);
	rtMatrix=[rtMatrix; subMatrix];
end

% Re-label the soma branches so they are in length order. The less label, the longer the branch.
% Exchange the label if the longer soma branch has larger label.
tempMatrix=rtMatrix;
sbIdx=find(~tempMatrix(:,1));
sbLen=tempMatrix(sbIdx,end);
sbLabel=tempMatrix(sbIdx,2);
[sbLabelS,si]=sort(sbLabel,'ascend');
sbLen2=sbLen(si);
[sv,si]=sort(sbLen2,'descend');
for i=1:length(sbIdx)
	if si(i)~=i
%		rtMatrix=tempMatrix(tempMatrix(:,1)==tempMatrix(sbIdx(mi),2));
		rtMatrix((tempMatrix(:,1)==sbLabelS(si(i))),1)=sbLabelS(i);
		rtMatrix((tempMatrix(:,2)==sbLabelS(si(i))),2)=sbLabelS(i);
	end
end

end
