function testDespekle

close all;

img=imread('../data/yangzhi/129-12.cut.png');

grayOri=getGrayImg(img);

addpath('./myLee');
addpath('./frost');
addpath('./2dNCDF');
addpath('./anisodiff');

colormap(jet);

colormap(hot(256));


%%
winSize=5;
img0=myLee(grayOri,winSize);

% figure,subplot(2,2,1);
figure, imshow(grayOri,[]);
image(img0);
figure, imshow(img0,[]);
title('Lee');

% figure,imagesc(img0);
% figure,imshow(img0,[]);
% figure,image(img0);

%%
r=5;
img1=fcnFrostFilter(grayOri,getnhood(strel('disk',r,0)));

%%
tmax=5;
img2 = twodncdf(grayOri, tmax);

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



