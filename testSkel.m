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

if flag==2 || flag==1
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

return;

end

%% Skel with or W/O ISAT.

close all;

if flag==4
    bwISAT=imread('../data/test/129-12.bw.png');
    skelResISAT=bwmorph(bwISAT,'thin',inf);
    img=imread('../data/test/129-12.cut.png');
    bw=img(:,:,2)>66;
    bw=keepLargest(bw);
    bw=imopen(bw,strel('disk',1));
    bw=imclose(bw,strel('disk',5));
    bw=imfill(bw,'holes');
    skelRes=bwmorph(bw,'thin',inf);
    nameStr='Neuron';
elseif flag==3
    bwISAT=imread('../data/test/2575 DIC115.bw.png');
    addpath(genpath('BaiSkeletonPruningDCE/'));
    skelResISAT=div_skeleton_new(4,1,1-bwISAT,13);
    skelResISAT=skelResISAT~=0;
    img=imread('../data/test/2575 DIC115.cut.png');
    bw=img(:,:,2)>45;
    bw=keepLargest(bw);
    bw=imopen(bw,strel('disk',1));
    bw=imclose(bw,strel('disk',5));
    bw=imfill(bw,'holes');
    skelRes=div_skeleton_new(4,1,1-bw,13);
    skelRes=skelRes~=0;
    figure,imshow(skelRes);
%     skelRes=bwmorph(bw,'skel',inf);
%     figure,imshow(skelRes);
    nameStr='Pollen';
end

figure,imshow(bwISAT);
saveas(gca,['ISATBw' nameStr '.eps'],'epsc');
figure,imshow(bw);
saveas(gca,['noISATBw' nameStr '.eps'],'epsc');
plotRes(img,skelRes);
saveas(gca,['noISATRes' nameStr '.eps'],'epsc');
plotRes(img,skelResISAT);
saveas(gca,['ISATRes' nameStr '.eps'],'epsc');

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