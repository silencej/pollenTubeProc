function [luCorner rlCorner]=getCutFrame(bw,cutMargin)
% Find the suitable cutting frame, which is represented by left-upper and
% right-lower corner.

% Initialization.
imgWidth=size(bw,2);
imgHeight=size(bw,1);

luRow=1;
luCol=1;
rlRow=imgHeight;
rlCol=imgWidth;

% luRow
for j=1:size(bw,1)
	res=find(bw(j,:), 1);
	if ~isempty(res)
		luRow=j;
		break;
	end
end
% luCol
for j=1:size(bw,2)
	res=find(bw(:,j), 1);
	if ~isempty(res)
		luCol=j;
		break;
	end
end
% rlRow
for j=luRow:size(bw,1)
	res=find(bw(j,:), 1);
	if isempty(res)
		rlRow=j;
		break;
	end
end
% rlCol
for j=luCol:size(bw,2)
	res=find(bw(:,j), 1);
	if isempty(res)
		rlCol=j;
		break;
	end
end

if luRow-cutMargin>0
	luRow=luRow-cutMargin;
end
if luCol-cutMargin>0
	luCol=luCol-cutMargin;
end
if rlRow+cutMargin<=imgHeight
	rlRow=rlRow+cutMargin;
end
if rlCol+cutMargin<=imgWidth
	rlCol=rlCol+cutMargin;
end

luCorner=[luRow luCol];
rlCorner=[rlRow rlCol];
end
