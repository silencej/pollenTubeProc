function [len idxLen]=getLenOnLine(sp,ep)
% gImg Must have only 1 parsi skel.
% sp is the first point on the skel.
% Tracing starts from sp and ep is the end point.
% sp must be an end point!
% ep may not reside on the line but contact it instead.
global gImg;

diagonalDis=sqrt(2);

idxLen=1; % idxLen is used to plot the branch position on the bbProfile, it's different from euclidean len.
[nbrs isNbr4]=nbr8(sp);
gImg(sp(1),sp(2))=0;
if isNbr4
	len=1;
else
	len=diagonalDis;
end
dis=abs(ep(1)-nbrs(1))+abs(ep(2)-nbrs(2));

% This is a classic 4-loop-in-skel problem. Hope it's rare!
% if ep(1)==2520 && ep(2)==1727
%	 disp();
% end

% while dis>2
% dis>3, for the classic 4-loop-in-skel problem.
while dis>3
	sp=nbrs(1,:); % Backbone img may have Ren-shape joint!
	[nbrs isNbr4]=nbr8(sp);
	if nbrs(1)==0
		fprintf(1,'Sp: %d %d. Ep: %d %d.\n',sp(1),sp(2),ep(1),ep(2));
		imwrite(gImg,'getLenOnLineError.png','png');
		error('getLenOnLine: Traced to the end point, No contact?\n');
	end
	gImg(sp(1),sp(2))=0;
	idxLen=idxLen+1;
	if isNbr4
		len=len+1;
	else
		len=len+diagonalDis;
	end
	dis=abs(ep(1)-sp(1))+abs(ep(2)-sp(2));
end

end

