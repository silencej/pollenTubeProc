function sp=findEndPoint(skelImg)
% Algorithm: find a non-zero pixel, and trace to an end point by erasing
% along the search route.
% The function will write on global img, but will restore it at the end.

% gImg is used as global img, which is used in function "nbr8".
global gImg;

gImg=skelImg;
clear skelImg;

% Save original gImg.
tempImg=gImg;

sp=find(gImg,1);
[sp(1) sp(2)]=ind2sub(size(gImg),sp);
% sp=[row col];
if length(sp)~=2
    error('sp is not a pair: %g.',sp);
end
nbr1=nbr8(sp);
gImg(sp(1),sp(2))=0;
if size(nbr1,1)~=1 % sp now is not an end point.
    while(nbr1(1)~=0)
        sp=nbr1(1,:);
%         if sp(1)==813
%             disp('here!');
%         end
%         fprintf(1,'sp: %d %d\n',sp(1),sp(2));
        % There could be a dead loop if Ren-shape is here. To solve this,
        % nbr8 will first return 4-nbrs before 8-nbrs.
        %     fprintf(1,'Now sp goes to %f\t%f\n',sp(1),sp(2));
        nbr1=nbr8(sp);
        gImg(sp(1),sp(2))=0;
    end
end

% Restore.
gImg=tempImg;

end