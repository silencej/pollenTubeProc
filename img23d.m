function img23d

file=getImgFileNames;

img=imread(file{1});
img2=rgb2gray(img);
img2=img2(1:1000,2040:3060);

close all;
figure;
% plot3(1:size(img,2),1:size(img,1));
mesh(double(img2));