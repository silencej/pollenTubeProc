function [ep len]=traceToEJ(sp,len)
% [ep len]=traceToEJ(sp,len)
% Input 'len' is the previous length. The output 'len' will add up on the
% input 'len'. 'len' defaults to 0.
% Trace the skeleton to an end point or a junction. Tracing starts from sp, and erases every pixel along the path, including sp and ep.

if nargin<2
	len=0;% len=0;
end

global gImg;

diagonalDis=sqrt(2);

[nbr1 isNbr4]=nbr8(sp);
gImg(sp(1),sp(2))=0;
% In case the input sp is an ep.
ep=sp; % If sp is an isolated point, ep=sp.

while (size(nbr1,1)==1 && nbr1(1)~=0) || size(nbr1,1)==2 % normal point will have 1 8-nbr since the previous one is filled!
	% nbr1 has 2-rows indicates there may be a Ren-shape (i.e. the present pos is
	% (1,2) or (2,3) at below. The pos can't be (2,2) if input sp is surely
	% an end point.), or a joint.
	%1  @
	%2  @@
	%3 @
	
	% Ren Shape. The first 4-nbr will be the ep.
	if size(nbr1,1)==2 && abs(nbr1(1,1)-nbr1(2,1))+abs(nbr1(1,2)-nbr1(2,2))==1
		% nbr1(1,:) is the 4-nbr.
		len=len+1;
		gImg(nbr1(1,1),nbr1(1,2))=0; % this is center of Ren-shape.
		ep=nbr1(1,:);
		%		 [nbr1 isNbr4]=nbr8(nbr1);
		break;
	end

	% Joint. ep=previous one.
	if size(nbr1,1)==2 && abs(nbr1(1,1)-nbr1(2,1))+abs(nbr1(1,2)-nbr1(2,2))~=1;
		% A joint is met.
		%1 @ @
		%2  @
		%3 @
		break;
	end
	
	if isNbr4
		len=len+1;
	else
		len=len+diagonalDis;
	end
	gImg(nbr1(1),nbr1(2))=0;
	ep=nbr1;
	[nbr1 isNbr4]=nbr8(nbr1);
end

% In case the input sp is an ep.
gImg(ep(1),ep(2))=0;

end

