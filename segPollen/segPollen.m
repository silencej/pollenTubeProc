function segPollen
% Input image is 16 bit.

fprintf(1,'===============\nsegPollen starts...\n');
close all;

pgThre=0.6;
r=1;
imgThre=1600;

% img=imread('../../data/guanPollen/G4-4 L.tif');
img=imread('../../data/guanPollen/G11-1.tif');
% img=imread('../../data/guanPollen/ren1-3 point5nM.tif');


[px,py] = gradient(double(img));
grad=sqrt(px.^2+py.^2);
% figure,imshow(grad,[]);
% contour(v,v,img), hold on, 
% figure;
% quiver(px,py);
pgBw=grad>300;

figure;
imshow(img,[]);
ellipH=imellipse;
pause;
fprintf(1,'Pollen Grain initial input is done.\n');

api=iptgetapi(ellipH);
elliPos=api.getPosition(); % Returns top-left position and Axial lengths: [x y Dhorizontal Dvertical].
Dl=elliPos(3);
Ds=elliPos(4);
if Dl<Ds
    temp=Dl;
    Dl=Ds;
    Ds=temp;
end
fprintf(1,'Specify pollen grain finished.\n');

% Example pixel: [erow ecol]; Used to keep the mother masks. The reference
% pixel is always the leftmost one of the ellipse.
erow=floor(elliPos(2)+elliPos(4)/2);
% ecol=ceil(Dl/2)+1;
ecol=floor(elliPos(1));
clear elliPos temp;
% tm=imellipse(fH,[erow floor(ecol-Ds/2) Ds Dl]);
tallMask=createMask(ellipH);
mtmCind=find(tallMask); % Clearing mask.
mTm=bwperim(tallMask,4); % mother tall mask.
mtmInd=find(mTm);
fm=imellipse(gca,[ecol floor(erow-Ds/2) Dl Ds]);
flatMask=createMask(fm);
mfmCind=find(flatMask);
mFm=bwperim(flatMask,4); % mother flat mask.
% [mfmr mfmc]=find(mFm);
mfmInd=find(mFm);
clear tm fm tallMask flatMask mTm mFm;
delete(ellipH);

% pgBw=img<imgThre; % Pollen grain bw.
% pgBw2=pgBw; % Save a copy


close all;
figure;
% imshow(img,[]);
imshow(pgBw);
hold on;

sz=size(pgBw);
rowNum=sz(1);
colNum=sz(2);
[row col]=find(pgBw,1);

% Plot mother ellipses.
plot(ecol,erow,'.r','Markersize',5);
[i j]=ind2sub(sz,mtmInd);
plot(j,i,'.b','Markersize',3);
[i j]=ind2sub(sz,mfmInd);
plot(j,i,'.g','Markersize',3);
        
while (row)
%     fprintf(1,'%d\t%d\n',row,col);
    tRatio=0;
    fRatio=0;
    if row-ceil(Dl/2)>0 && row+ceil(Dl/2)<rowNum && col+ceil(Ds)<colNum
%        tmr=mtmr+row-erow;
 %       tmc=mtmc+col-ecol;
        tmInd=mtmInd+row-erow+(col-ecol)*rowNum;
%         tRatio=sum(pgBw(sub2ind(sz,tmr,tmc)))/size(tmr,1);
        tRatio=sum(pgBw(tmInd))/size(tmInd,1);
%         plot(col,row,'.r','Markersize',3);
%         [i j]=ind2sub(sz,tmInd);
%         plot(j,i,'.b','Markersize',1);
%         fprintf(1,'denominator=%f, tRatio= %f.\n',sum(pgBw(tmInd)),tRatio);
    end
    if row-ceil(Ds/2)>0 && row+ceil(Ds/2)<rowNum && col+ceil(Dl)<colNum
%         fmr=mfmr+row-erow;
%         fmc=mfmc+col-ecol;
        fmInd=mfmInd+row-erow+(col-ecol)*rowNum;
%         fRatio=sum(pgBw(sub2ind(sz,fmr,fmc)))/size(fmr,1);
        fRatio=sum(pgBw(fmInd))/size(fmInd,1);
%         fprintf(1,'denominator=%f, fRatio= %f.\n',sum(pgBw(fmInd)),fRatio);
    end
    if row-r<=0
        rowLeft=1;
    else
        rowLeft=row-r;
    end
    if row+r>rowNum
        rowRight=rowNum;
    else
        rowRight=row+r;
    end
    if col-r<=0
        colLeft=1;
    else
        colLeft=col-r;
    end
    if col+r>colNum
        colRight=colNum;
    else
        colRight=col+r;
    end
    pgBw(rowLeft:rowRight,colLeft:colRight)=0;
    if tRatio>=fRatio && tRatio>=pgThre
        rectangle('Position',[col row-floor(Dl/2) Ds Dl],'Curvature',[1 1],'LineWidth',2,'EdgeColor','r');
        tmCind=mtmCind+row-erow+(col-ecol)*rowNum;
        pgBw(tmCind)=0;
        [row col]=find(pgBw,1);
        continue;
    end
    if fRatio>=pgThre
        rectangle('Position',[col row-floor(Ds/2) Dl Ds],'Curvature',[1 1],'LineWidth',2,'EdgeColor','r');
        fmCind=mfmCind+row-erow+(col-ecol)*rowNum;
        pgBw(fmCind)=0;
    end
    [row col]=find(pgBw,1);
end

disp('Finished.');


end