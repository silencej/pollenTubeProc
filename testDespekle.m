function testDespekle

close all;

img=imread('../data/yangzhi/129-12.cut.png');

grayOri=getGrayImg(img);

addpath('./myLee');
addpath('./frost');
addpath('./2dNCDF');
addpath('./anisodiff');

% colormap(jet);

% colormap(hot(256));


%%
winSize=9;
img0=myLee(grayOri,winSize);

% figure,subplot(2,2,1);
% figure, imshow(grayOri,[]);
figure, imagesc(grayOri);
% figure, colormap(jet); imagesc(grayOri);
% figure, imagesc(img0);
% figure, imshow(img0,[]);
goRes=adapthisteq(grayOri);
figure, imagesc(goRes);
% figure, imshow(goRes>graythresh(goRes)*255-30);
img0Res=adapthisteq(img0);
figure, imagesc(img0Res);
% figure, imshow(img0Res>graythresh(img0Res)*255-35);
% title('Lee');

% figure,imagesc(img0);
% figure,imshow(img0,[]);
% figure,image(img0);

%%
r=5;
img1=fcnFrostFilter(grayOri,getnhood(strel('disk',r,0)));
img1Res=adapthisteq(img1);
figure, imagesc(img1Res);
figure,imshow(img1Res>graythresh(img1Res)*255-15);

%%
tmax=5;
img2 = twodncdf(grayOri, tmax);
img2=uint8(img2);
img2Res=adapthisteq(img2);
figure, imagesc(img2Res);
figure,imshow(img2Res>graythresh(img2Res)*255);

%%

num_iter = 15;
delta_t = 1/7;
kappa = 30;
option = 2;
img3 = anisodiff2D(grayOri,num_iter,delta_t,kappa,option);

%%

% subplot(2,2,2);
figure;
image(img1);
title('Frost');
% subplot(2,2,3);
figure;
image(img2);
title('iNCDF');
% subplot(2,2,4);
figure;
image(img3);
title('Aniso');



