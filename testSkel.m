function testSkel(flag)


%%
close all;

if flag==2
    bw=imread('../data/test/129-12.bw.png');
    nameStr='Neuron';
elseif flag==1
    bw=imread('../data/test/2575 DIC115.bw.png');
    nameStr='Pollen';
end
% grayOri=getGrayImg(img);

tic;
thinRes=bwmorph(bw,'thin',inf);
t1=toc;
plotRes(bw,thinRes);
saveas(gca,['thinRes' nameStr '.eps'],'epsc');

tic;
skelRes=bwmorph(bw,'skel',inf);
t2=toc;
plotRes(bw, skelRes);
saveas(gca,['skelRes' nameStr '.eps'],'epsc');

addpath(genpath('BaiSkeletonPruningDCE/'));
tic;
baiRes=div_skeleton_new(4,1,1-bw,13);
t3=toc;
baiRes=baiRes~=0;
plotRes(bw,baiRes);
saveas(gca,['baiRes' nameStr '.eps'],'epsc');

figure, bar([t1 t2 t3]);
xlabel('Methods');
ylabel('Time (s)');
set(gca,'xticklabel',{'Thinning','MA','Bai''s method'});
saveas(gca,['skelTime' nameStr '.eps'],'epsc');

end

function plotRes(bw,res)

% rgbImg=zeros(size(bw,1),size(bw,2),3);
% rgbImg=putBwlineOnRgb(rgbImg,bw,[255 255 255]);
% figure,imshow(putBwlineOnRgb(rgbImg,skelRes,[255 0 0]));

figure,imshow(bw);
hold on;
inds=find(res);
[c d]=ind2sub(size(bw),inds);
plot(d,c,'.r');
hold off;

end