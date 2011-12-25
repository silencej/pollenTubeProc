function preproBig(thre)

global rowTileNum colTileNum debugFlag areaMin verNum;

if nargin<1
    thre=18;
end

% Parameters.
rowTileNum=7;
colTileNum=7;
debugFlag=1;
areaMin=200;
verNum=5; % skeleton ver num.

close all;
warning off Images:initSize:adjustingMag; % Turn off image scaling warnings.
iptsetpref('ImshowBorder','tight'); % Make imshow display no border and thus print will save no white border.

files=getImgFileNames;
if files{1}==0
    return;
end

% if length(files)>1
%     fprintf(1,'Multiple image input, thus no plot output.\n');
%     return;
% end

for i=1:length(files)
    preproFile(files{1},thre);
end

end

function preproFile(filename,thre)

global areaMin;

img=imread(filename);
grayImg=getGrayImg(img);
% bw=otsuThreImg(grayImg);
bw=(grayImg>thre);

% if debugFlag
%     figure,imshow(img);
% end

% testBw=bw(1348:1485,2884:2990);

% res=bwmorph(testBw,'thin',inf);
% figure,imshow(res);

% rBw=~testBw;
% dis=bwdist(rBw);

% figure,imshow(testBw);
% figure,imshow(dis,[]);

% img=putTileGrid(img);

% figure,imshow(img);

%% Clear single point.

bw=bwmorph(bw,'clean',8);

%% Clear border.

bw=clearTileBorder(bw);

%% Delete connected pollen.

pollen=findPollen(bw,5);

% figure,imshow(bw);

% figure,imshow(putOnImg(img,pollen(:,1:2)));

% hold on;
% for i=size(pollen,1)
%     rectangle('Position',[pollen(i,2)-pollen(i,3) pollen(i,1)-pollen(i,3) 2*pollen(i,3) 2*pollen(i,3)],'Curvature',[1 1],'EdgeColor','r');
%     plot(pollen(i,2),pollen(i,1),'or');
% end
% hold off;

[bw L pollen]=deleteConPollen(bw,pollen);

L=keepOnlyPollen(pollen,L,areaMin);
bw=L~=0;

bw=imfill(bw,'holes');

[pathstr, name]=fileparts(filename);
bwFile=fullfile(pathstr,[name '.bw.png']);
imwrite(bw,bwFile,'png');

% Get lengths.
% res=getLength(bw,pollen);

% figure,imshow(bw);

end

%%

function pollen=findPollen(bw, radMin)
% pollen format:
% [rowPos, colPos, pollenRad]

if nargin<2
    radMin=4;
end

bw(1:radMin,:)=0;
bw(end-radMin+1:end,:)=0;
bw(:,1:radMin)=0;
bw(:,end-radMin+1:end)=0;

bw=~bw;
dis=bwdist(bw);
tempDis=dis>=radMin;
dis=dis.*tempDis;
disPInd=find(dis);
% winF=fspecial('disk',radMin);
% winF=winF>0;

% Get rid of the pixel and other pixels if there is a pixel with higher
% distance value than them.
for i=1:length(disPInd)
    if dis(disPInd(i))
        [row col]=ind2sub(size(dis),disPInd(i));
        window=dis(row-radMin:row+radMin,col-radMin:col+radMin);
        [mv mi]=max(window(:));
        [rowM colM]=ind2sub(size(window),mi);
        tempWindow=zeros(size(window));
        tempWindow(rowM,colM)=window(rowM,colM);
        dis(row-radMin:row+radMin,col-radMin:col+radMin)=tempWindow;
    end
end

inds=find(dis);
[pollen(:,1) pollen(:,2)]=ind2sub(size(dis),inds);
pollen(:,3)=dis(inds);

end

function img=putOnImg(img,subs,r,g,b)

if nargin<3
    r=255;
    g=0;
    b=0;
end

img(sub2ind(size(img),subs(:,1),subs(:,2),1*ones(size(subs,1),1)))=r;
img(sub2ind(size(img),subs(:,1),subs(:,2),2*ones(size(subs,1),1)))=g;
img(sub2ind(size(img),subs(:,1),subs(:,2),3*ones(size(subs,1),1)))=b;

end

function img=putTileGrid(img)

global rowTileNum colTileNum debugFlag;

rowNum=size(img,1);
colNum=size(img,2);

% Tlen: tiling length.
rowTlen=floor(rowNum/rowTileNum);
colTlen=floor(colNum/colTileNum);

tileBorderSubs=[(1:rowNum)' ones(rowNum,1)];
tileBorderSubs=[tileBorderSubs; (1:rowNum)' ones(rowNum,1)+colTlen-1];
for i=2:colTileNum
    tileBorderSubs=[tileBorderSubs; (1:rowNum)' ones(rowNum,1)+(i-1)*colTlen];
    tileBorderSubs=[tileBorderSubs ; (1:rowNum)' ones(rowNum,1)+i*colTlen-1];
end
for i=1:rowTileNum
    tileBorderSubs=[tileBorderSubs ; ones(colNum,1)+(i-1)*rowTlen (1:colNum)'];
    tileBorderSubs=[tileBorderSubs ; ones(colNum,1)+i*rowTlen-1 (1:colNum)'];
end

if ndims(img)==3
    img(sub2ind(size(img),tileBorderSubs(:,1),tileBorderSubs(:,2),1*ones(size(tileBorderSubs,1),1)))=255;
    img(sub2ind(size(img),tileBorderSubs(:,1),tileBorderSubs(:,2),2*ones(size(tileBorderSubs,1),1)))=255;
    img(sub2ind(size(img),tileBorderSubs(:,1),tileBorderSubs(:,2),3*ones(size(tileBorderSubs,1),1)))=255;
end

end

function subs=getTileBorder(bw)

global rowTileNum colTileNum;

rowNum=size(bw,1);
colNum=size(bw,2);

% Tlen: tiling length.
rowTlen=rowNum/rowTileNum;
colTlen=colNum/colTileNum;

tileBorderSubs=[(1:rowNum)' ones(rowNum,1)];
tileBorderSubs=[tileBorderSubs; (1:rowNum)' ones(rowNum,1)+colTlen-1];
for i=2:colTileNum
    tileBorderSubs=[tileBorderSubs; (1:rowNum)' ones(rowNum,1)+(i-1)*rowTlen];
    tileBorderSubs=[tileBorderSubs ; (1:rowNum)' ones(rowNum,1)+i*rowTlen-1];
end
for i=1:rowTileNum
    tileBorderSubs=[tileBorderSubs ; ones(colNum,1)+(i-1)*colTlen (1:colNum)'];
    tileBorderSubs=[tileBorderSubs ; ones(colNum,1)+i*colTlen-1 (1:colNum)'];
end

subs=tileBorderSubs;

end

function bw=clearTileBorder(bw)

subs=getTileBorder(bw);

% Reverse.
bw=~bw;
subs=subs( ~bw(sub2ind(size(bw),subs(:,1),subs(:,2))) ,:);


tic;
for i=1:size(subs,1)
    if ~bw(subs(i,1),subs(i,2))
        bw=imfill(bw,subs(i,:),8);
    end
end
toc;

bw=~bw;

end

function [bw L pollen]=deleteConPollen(bw,pollen)

L=bwlabel(bw,8);

plen=size(pollen,1);
for i=1:plen-1
    for j=i+1:plen
        if pollen(i,1) && pollen(j,1) && L(pollen(i,1),pollen(i,2)) && L(pollen(j,1),pollen(j,2)) && L(pollen(i,1),pollen(i,2))==L(pollen(j,1),pollen(j,2))
            L(L==L(pollen(i,1),pollen(i,2)))=0;
            pollen(i,:)=[0 0 0];
            pollen(j,:)=[0 0 0];
        end
    end
end

% subs=getTileBorder(bw);
% 
% for i=1:size(subs,1)
%     if ~bw(subs(i,1),subs(i,2))
%         L(L==L(subs(i,1),subs(i,2)))=0;
%     end
% end

pollen=pollen( find(pollen(:,1)), :);

bw=L~=0;

end

function [L pollen]=keepOnlyPollen(pollen,L, areaMin)
% Keep the connected component if it contains one pollen point. Delete all
% non-pollen.
% More, if the area of the component is < areaMin, it will also be deleted.

if nargin<3
    areaMin=150;
end

pNum=0;
tempPollen=[0 0 0];
tempL=zeros(size(L));
for i=1:size(pollen,1)
    mask=L==L(pollen(i,1),pollen(i,2));
    if length(find(mask(:)))>areaMin
        tempL(mask)=L(pollen(i,1),pollen(i,2));
        pNum=pNum+1;
        tempPollen(pNum,:)=pollen(i,:);
    end
end

L=tempL;
pollen=tempPollen;

end

