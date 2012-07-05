function testSkel


%%
close all;

img=imread('../data/129-12.bw.png');
grayOri=getGrayImg(img);

tic;
thinRes=bwmorph(bw,'thin',inf);
t1=toc;

% figure,imshow(skel);

%	 skel=bwmorph(bw,'skel',inf);
%	 figure,imshow(bw);
% else
% skel=div_skeleton_new(4,1,1-bw,0);
% [skel,I0,x,y,x1,y1,aa,bb]=div_skeleton_new(4,1,1-bw,60);

figure,imshow();

tic;
baiRes=div_skeleton_new(4,1,1-bw,handles.skelVerNum);
t2=toc;

end