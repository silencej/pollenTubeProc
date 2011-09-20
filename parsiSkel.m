function img2=parsiSkel(img2)
global img imgWidth imgHeight;
img=img2;
clear img2;
% parsiSkel(img)
% Make the skeleton parsimonious, e.g. points of stroke have 2 8-neighbours, while points at 3-junction have 3 8-neighbours.
% For example, if a pixel has close 4-neighbours, where they form a L-shape
% @@@
% @
% @
% will be reduced to
%  @@
% @
% @
% While a straight line
% @@@@@@@
% will be kept, since the 4-neighbours are across not close.
% Algorithm: delete all pixels with 2 or more 4-way neighbours from skeleton.

imgHeight=size(img,1);
imgWidth=size(img,2);
sizeImg=size(img);

img=img~=0;
idx=find(img);

% for i=1:imgWidth*imgHeight
% 	[row col]=ind2sub(sizeImg,i);
% %	nbrs=hasLNbr([row col]);
% 	if img(row,col)>0 && hasLNbr([row col]) % has L Nbr?
% 		img(row,col)=0;
% 	end
% end

for i=1:length(idx)
    [row col]=ind2sub(sizeImg,idx(i));
	if img(row,col)>0 && hasLNbr([row col]) % has L Nbr?
		img(row,col)=0;
	end
end

img2=img;
clear img;
% End of parsiSkel.
end

function nbrs=nbr4(p)
global img imgWidth imgHeight;
len=0;
% NOTE: img(p) is img(row,col) thus img(py,px).
px=p(2);
py=p(1);
nbrs=[0 0]; % the nbrs will be in clock-wise.
% px is col, py is row.
% clock-wise, starting from north nbr.

nbrsIdx=[py-1 px; py px+1; py+1 px; py px-1];
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
for j=1:size(nbrsIdx,1)
	if img(nbrsIdx(j,1),nbrsIdx(j,2))
		len=len+1;
		nbrs(len,:)=nbrsIdx(j,:);
	end
end
end

function flag=hasLNbr(p)
% Check if the pixel has L-shape 4-neighbours.
global img imgWidth imgHeight;

flag=0;
nbrs=nbr4(p);
% has more than 2 4-nbrs, sure that L-shape.
if size(nbrs,1)>=3
	flag=1;
end

if size(nbrs,1)==2 && abs(nbrs(2,1)-nbrs(1,1))==1
	flag=1;
% Correct the Chinese 'Ren'-shape problem:
% If delete the center pixel, the component is not connected anymore!
%1  @
%2  @@
%3 @
% (3,2) is the candidates to be filled while (2,1) is not since (2,1) is
% ahead of (2,2), the on-processing point, in image index.
% So after correction it will become:
%  @
% @ @
% @
% Ren-shape Dilemma:
% Condition 1 - go lower right:
%1 @  @
%2  @  @
%3   @@ @
%4    @  @
% After removing (3,4), you add (3,5), and new Ren-shape
% appears and the procedure come up next time at (3,5) and then (4,5).
% Condition 2 - go lower left:
%1    @
%2   @
%3  @@ @
%4 @  @
%5   @
% After removing (3,3), you add (4,3), when it comes to
% (4,3), the procedure can't goes on. The correction is to choose
% (4,2), and comes back to (4,2) to proceed the procedure. Then it goes to
% lower left.
% HOWEVER, this type of correction can cause a problem like this:
%1 @@
%2   @@
%3   @
% Be corrected to
%1 @@
%2  @ @
%3   @
% First, (1,2) becomes a new Ren-shape center, but (1,2) is ahead of (2,3)
% and has already been processed. So it needs to run the procedure from
% beginning again.
% Second, the original Ren-shape may indicates a joint with 3 branches, but
% the correction changes the joint into a curved line.
% So the best solution is to keep the Ren-shape and take care in
% getBackbone script.
%
% There are several conditions which can be categorized as 0-4nbr, 1-4nbr,
% 2-4nbrs, 3-4nbrs, and 4-4nbrs. The Ren-shape dilemma belongs to 2-4nbrs
% category. For more than 1-4nbr, only Ren-shape pixel should be kept and
% the others be erased.
% For 3-4nbrs, a condition like
%1 @@@
%2  @
% Will be modified as
%1 @ @
%2  @
% and whether it's joint or not depends on context.
% So the following is a curved straight line.
%1
%2 @@ @@
%3   @
%4
% While the following is a joint, and the joint center is considered as (3,3).
%1
%2 @@ @@
%3   @
%4   @
%

    nbr1=nbrs(1,:);
    nbr2=nbrs(2,:);
    % [row col] is the cross-p in the Ren-shape.
    if nbr1(1)==p(1) % nbr1 is in the same row with p.
        col=p(2)+p(2)-nbr1(2);
        row=p(1)+p(1)-nbr2(1);
    else
        col=p(2)+p(2)-nbr2(2);
        row=p(1)+p(1)-nbr1(1);
    end
% The following correction is not good.
%     if img(row,col)>0
%         nbrsC1=nbr4([row,p(2)]); % Candidate 1's nbrs.
%         nbrsC2=nbr4([p(1),col]); % Candidate 2's nbrs.
%         if size(nbrsC1,1)==2 % only have p and cross-p as 4-nbrs.
%             img(row,p(2))=1;
%         elseif size(nbrsC2,1)==2
%             img(p(1),col)=1;
%         else
%             fprintf(1,'ERROR: Dilemma Appear for Ren-shape!!!\n');
%             return;
%         end
%     end

    if row>0 && row<=imgHeight && col>0 && col<=imgWidth && img(row,col)>0
        flag=0; % Keep the Ren-shape center.
    end
end

flag=flag>0;

% End of hasLNbr.
end


