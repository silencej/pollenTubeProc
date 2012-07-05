function testSkel


%%
close all;

bw=imread('../data/test/129-12.bw.png');
% bw=imread('../data/test/2575 DIC115.bw.png');
% grayOri=getGrayImg(img);

tic;
thinRes=bwmorph(bw,'thin',inf);
t1=toc;

% figure,imshow(skel);

%	 skel=bwmorph(bw,'skel',inf);
%	 figure,imshow(bw);
% else
% skel=div_skeleton_new(4,1,1-bw,0);
% [skel,I0,x,y,x1,y1,aa,bb]=div_skeleton_new(4,1,1-bw,60);

rgbImg=zeros(size(bw,1),size(bw,2),3);
rgbImg=putBwlineOnRgb(rgbImg,bw,[255 255 255]);
figure,imshow(putBwlineOnRgb(rgbImg,thinRes,[255 0 0]));

addpath(genpath('BaiSkeletonPruningDCE/'));
tic;
baiRes=div_skeleton_new(4,1,1-bw,13);
t2=toc;
baiRes=baiRes~=0;

rgbImg=zeros(size(bw,1),size(bw,2),3);
rgbImg=putBwlineOnRgb(rgbImg,bw,[255 255 255]);
figure,imshow(putBwlineOnRgb(rgbImg,baiRes,[255 0 0]));

figure, bar([t1 t2]);
xlabel('Methods');
ylabel('Time (s)');
set(gca,'xticklabel',{'Thinning','Bai''s method'});

end