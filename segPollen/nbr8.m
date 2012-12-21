function [nbrs isNbr4]=nbr8(p)
% Find neighbours clockwise.
% p: [row col].
% nbrs: [row col]. isNbr4 is ture if the nbrs is a 4-nbr.
% NOTE: 4-nbrs are always ahead of other 8-nbrs in nbrs, which is good for tracing Ren-shape.
% Return [0 0] and isNbr4=2 if no nbr is found.
global gImg;

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
	if gImg(nbrsIdx4(i,1),nbrsIdx4(i,2))
		len=len+1;
		nbrs(len,:)=nbrsIdx4(i,:);
		isNbr4(len)=1;
	end
end

for i=1:size(nbrsIdx8,1)
	if gImg(nbrsIdx8(i,1),nbrsIdx8(i,2))
		len=len+1;
		nbrs(len,:)=nbrsIdx8(i,:);
		isNbr4(len)=0;
	end
end

% End of nbr.
end

%%

function nbrsIdx=cleanNbrs(nbrsIdx)
% Clean all nbrs with illegal subcripts such as 0 or out of border.

global gImg;

imgWidth=size(gImg,2);
imgHeight=size(gImg,1);

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

