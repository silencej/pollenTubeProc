function [grayOri channel]=getGrayImg(ori)
% channel: the RGB channel number used.

if ndims(ori)==2
    grayOri=ori;
    return;
end
if ndims(ori)>3
    error('getGrayImg: input image has more than 3 dims./n');
end

img1=ori(:,:,1);
img2=ori(:,:,2);
img3=ori(:,:,3);
% [mv mi]=max([max(img1(:)) max(img2(:)) max(img3(:))]);
[mv mi]=max([mean(img1(:)) mean(img2(:)) mean(img3(:))]);
sprintf(num2str(mv));
% clear img1 img2 img3;
grayOri=ori(:,:,mi);
channel=mi;

end