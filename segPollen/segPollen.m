function segPollen

close all;
haloThre=3200;

% global img fH bw;
close all;

img=imread('../../data/guanPollen/G11-1.tif');

% img=imcomplement(img);
% % figure,imshow(img,[]);
% 
% % figure,imshow(img2,[]);
% % img=imadjust(img);
% % img=adapthisteq(img);
% % img2=imclose(img,strel('ball',3,10000,8));
% figure,imshow(img,[]);

% bw=tileSeg(img);
% figure,imshow(bw);

%% Symmetry finding.
% winsize=61;
% halfWin=(winsize-1)/2;
% rowNum=size(img,1);
% colNum=size(img,2);
% img=imclearborder(img,8);
% thre=max(img(:))*0.8;
% bwThre=40;
% disThre=10;
% pg=zeros(size(img));
% 
% for i=1+halfWin:rowNum-halfWin
%     for j=1+halfWin:colNum-halfWin
%         win=img(i-halfWin:i+halfWin,j-halfWin:j+halfWin);
%         if max(win(:))<thre
%             pg(i,j)=0;
%             continue;
%         end
%         bw=im2bw(win,graythresh(win));
%         if bwarea(bw)<bwThre
%             pg(i,j)=0;
%             continue;
%         end
%         rowCenter=sum(bw(halfWin+1,:).*(-halfWin:halfWin));
%         colCenter=sum(bw(:,halfWin+1)'.*(-halfWin:halfWin));
%         if abs(rowCenter)+abs(colCenter)>disThre
%             pg(i,j)=0;
%             continue;
%         end
%         pg(i,j)=1;
%     end
% end
% 
% figure,imshow(pg);

%% morphological operations.

% img2=imclose(img,strel('ball',1,10000,8));
% figure,imshow(img2,[]);
% figure,imshow(im2bw(img2,graythresh(img2)));

% pg=imfilter(img,fspecial('gaussian',[9,9],1.5),'replicate');
% % figure,imshow(img2,[]);
% pg=imopen(pg,strel('ball',50,63000,8));
% pg=img-pg;
% figure,imshow(pg,[]);
% pgBw=im2bw(pg,graythresh(pg));
% figure,imshow(pgBw);

%%
ed1=edge(img,'canny',[0.005,0.4],1);
figure,imshow(ed1);
pgBw=ed1;
% pgBw=bwmorph(pgBw,'skel',inf);
figure,imshow(pgBw);

addpath(genpath('sam'));
[bestEllipses, e] = findellipse(pgBw);

img=imclose(img,strel('disk',3,8));
figure,imshow(img,[]);
% figure,imshow(im2bw(img,graythresh(img)));

% img2=imfilter(img,fspecial('gaussian',[3,3],1));
img=imfill(img,'holes');
figure,imshow(img,[]);
bg=imopen(img,strel('ball',50,20000,8));
img=img-bg;
figure,imshow(img,[]);

img2=imclose(img,strel('ball',3,10000,8));
figure,imshow(img2,[]);
figure,imshow(im2bw(img2,graythresh(img2)));

img=imadjust(img);
img=adapthisteq(img);
img(img<=30000)=30000;
figure,imshow(img,[]);
ed1=edge(img,'canny',[0.005,0.4],1);
figure,imshow(ed1);
figure,imshow(imfill(ed1,'holes'));

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
patt=traceContour(patt);
figure,plot(patt(:,1),patt(:,2));

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