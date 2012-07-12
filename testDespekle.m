function testDespekle

% img=imread('../data/test/129-12.cut.png');

% grayOri=getGrayImg(img);


%%

close all;

img=imread('../data/test/129-12.cut.png');
grayOri=getGrayImg(img);

figure, imshow(grayOri);
saveas(gca,'129-12CutGray.eps','epsc');
figure, imhist(grayOri);
ylim([0,2*10^5]);
saveas(gca,'129-12CutGrayHist.eps','epsc');
gray2=adapthisteq(grayOri);
figure, imshow(gray2);
saveas(gca,'129-12CutClahe.eps','epsc');
figure, imhist(gray2);
ylim([0,7*10^4]);
saveas(gca,'129-12CutClaheHist.eps','epsc');

close all;

%%

close all;

img=imread('../data/test/129-12.cut.png');
grayOri=getGrayImg(img);

% colormap(jet(256));

gray1=imadjust(grayOri,stretchlim(grayOri,0));
% figure,imhist(gray1);
figure,imshow(gray1);
saveas(gca,'129-12CutLM.eps','epsc');
figure,imagesc(gray1);
saveas(gca,'129-12CutLMSc.eps','epsc');
figure,imagesc(histeq(grayOri));
saveas(gca,'129-12CutHisteq.eps','epsc');
figure, imagesc(adapthisteq(grayOri));
% Clahe pseducolor.
saveas(gca,'129-12CutClaheSc.eps','epsc');

close all;

%%

% colormap(jet);

% colormap(hot(256));

% figure,subplot(2,2,1);
% figure, imshow(grayOri,[]);
figure, imagesc(grayOri);
% figure, colormap(jet); imagesc(grayOri);
% figure, imagesc(img0);
% figure, imshow(img0,[]);
goRes=adapthisteq(grayOri);
figure, imagesc(goRes);

%%

addpath('./myLee');

winSize=9;
ts=tic;
img0=myLee(grayOri,winSize);
t0=toc(ts);
% figure, imshow(goRes>graythresh(goRes)*255-30);
img0Res=adapthisteq(img0);
figure, imagesc(img0Res);
% figure, imshow(img0Res>graythresh(img0Res)*255-35);
% title('Lee');

% figure,imagesc(img0);
% figure,imshow(img0,[]);
% figure,image(img0);

%%
addpath('./frost');

r=5;
ts=tic;
img1=fcnFrostFilter(grayOri,getnhood(strel('disk',r,0)));
% img1Res=img1;
t1=toc(ts);
img1Res=adapthisteq(img1);
figure, imagesc(img1Res);
% figure,imshow(img1Res>graythresh(img1Res)*255-15);

%%

addpath('./2dNCDF');

tmax=5;
ts=tic;
img2 = twodncdf(grayOri, tmax);
t2=toc(ts);
img2=uint8(img2);
img2Res=adapthisteq(img2);
figure, imagesc(img2Res);
% figure,imshow(img2Res>graythresh(img2Res)*255);

%%

addpath('./anisodiff');

num_iter = 15;
delta_t = 1/7;
kappa = 30;
option = 2;
ts=tic;
img3 = anisodiff2D(grayOri,num_iter,delta_t,kappa,option);
t3=toc(ts);
img3Res=adapthisteq(uint8(img3));
figure, imagesc(img3Res);

%%
figure, plot([t0 t1 t2 t3]);
set(gca,'XTick',1:4)
set(gca,'XTickLabel',{'Lee','Frost','iNCDF','ADPM'});
xlim([0.8 4.2]);
ylim([-10 210]);


%%
% Lee + CLAHE
% CLAHE + Lee

addpath('./myLee');

close all;

img=imread('../data/test/129-12.cut.png');
grayOri=getGrayImg(img);

winSize=9;
% ts=tic;
img0=myLee(grayOri,winSize);
% t0=toc(ts);
% figure, imshow(goRes>graythresh(goRes)*255-30);
leeClahe=adapthisteq(img0);

figure, imagesc(leeClahe);
saveas(gca,'leeClahe.eps','epsc');
% print(gcf, '-depsc2','-r300','leeClahePrint.eps');

img0=adapthisteq(grayOri);
claheLee=myLee(img0,winSize);

figure, imagesc(claheLee);
saveas(gca,'claheLee.eps','epsc');


%%
% HE+Lee vs CLAHE+Lee

addpath('./myLee');

close all;

img=imread('../data/test/129-12.cut.png');
grayOri=getGrayImg(img);

winSize=9;
img0=myLee(grayOri,winSize);
leeClahe=adapthisteq(img0);
leeHe=histeq(img0);
% heLee=histeq(grayOri);
% heLee=myLee(heLee,winSize);

figure, imagesc(leeClahe);
saveas(gca,'leeClahe.eps','epsc');
figure, imshow(leeClahe>=graythresh(leeClahe)*255);
saveas(gca,'leeClaheOtsu.eps','epsc');
figure, imagesc(leeHe);
saveas(gca,'leeHe.eps','epsc');
figure, imshow(leeHe>=graythresh(leeHe)*255);
saveas(gca,'leeHeOtsu.eps','epsc');
figure, imshow(grayOri>=graythresh(grayOri)*255);
saveas(gca,'oriOtsu.eps','epsc');

% figure, imagesc(heLee);
% saveas(gca,'heLee.eps','epsc');


%%

% % subplot(2,2,2);
% figure;
% image(img1);
% title('Frost');
% % subplot(2,2,3);
% figure;
% image(img2);
% title('iNCDF');
% % subplot(2,2,4);
% figure;
% image(img3);
% title('Aniso');



