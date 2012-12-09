function segPollen

close all;
haloThre=3200;

global img fH bw;

img=imread('../../data/guanPollen/G11-1.tif');

% figure;
% imshow(img,[]);
% eh=imellipse;
% pos=wait(eh); % [tlRow tlCol width height], tl: top left.
% % tempImg=ellipCrop(img,pos);
% mask=poly2mask(pos(:,1),pos(:,2),size(img,1),size(img,2));
% % eh=imellipse(gca,[10 10 ]);
% patt=bwperim(mask);
% [row col]=find(patt);
% permOdd=1:2:length(row);
% permEven=2:2:length(row);
% permEven=permEven(end:-1:1);
% perm=[permOdd permEven];
% row=row(perm);
% col=col(perm);
% patt=[col row];
% save('patt.mat','patt');

load 'patt.mat';
row=patt(:,2);
col=patt(:,1);
permOdd=1:2:length(row);
permEven=2:2:length(row);
permEven=permEven(end:-1:1);
perm=[permOdd permEven];
row=row(perm);
col=col(perm);
patt=[col row];

addpath(genpath('fght'));
rhorange = 0.9:0.1:1.2;
thetarange = -pi/40:pi/60:pi/40;
kwidth = 5;
[qlt, scl, rot, xpk, ypk] = gfht(imcomplement(img), patt, rhorange, thetarange, kwidth);

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