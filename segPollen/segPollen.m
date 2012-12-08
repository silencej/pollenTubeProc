function segPollen

close all;
haloThre=3200;

global img fH bw;

img=imread('../../data/guanPollen/G11-1.tif');
img=imcomplement(img);
img=imadjust(img);
% figure,imshow(img);
% img2=adapthisteq(img,'Distribution','uniform');
% figure,imshow(img2);
img=adapthisteq(img,'Distribution','exponential');
img(img<=haloThre)=0;
% figure,imshow(img);
% img=imfilter(img,fspecial('disk', 3));
% ui(img);
% rayleigh
bw=img<2500;
ed=edge(img,'canny');
bw=bw&ed;
showBw;
bw=imfill(bw,'holes');
bw=imerode(bw,strel('disk',10));
fH=figure;
showBw;
% imshow(bw1);

end

function showBw
global bw img fH;
[row col]=find(bw);
figure(fH);
imshow(img,[],'Parent',gca);
hold on;
plot(col,row,'.r','Markersize',5);
hold off;
end