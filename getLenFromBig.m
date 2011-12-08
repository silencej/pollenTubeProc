function getLenFromBig

global rowTileNum colTileNum debugFlag verNum;

% Parameters.
rowTileNum=7;
colTileNum=7;
debugFlag=1;
verNum=3; % skeleton ver num.

close all;
warning off Images:initSize:adjustingMag; % Turn off image scaling warnings.
warning off all;
iptsetpref('ImshowBorder','tight'); % Make imshow display no border and thus print will save no white border.

files=getImgFileNames({'*.bw.png','Bitwise Image'});
if files{1}==0
    return;
end


for i=1:length(files)
    getLenFromFile(files{1});
end

end

function getLenFromFile(filename)
% Get lengths.

bw=imread(filename);

if ~islogical(bw)
    fsprintf(1,'getLenFromFile: %s is not logical, but %s\n',filename,class(bw));
    bw=bw~=0;
end

res=getLength(bw);

% Save result: count textfile and image.
[pathstr, name]=fileparts(filename);
[tempstr, name]=fileparts(name);
imageFile=fullfile(pathstr,[name '_res.png']);
% imsave(gca,imageFile,'png');
print('-dpng', '-r300',imageFile);
countFile=fullfile(pathstr,[name '.txt']);
fid=fopen(countFile,'w');
fprintf(fid,'%6.2f\n',res(:,3));
fclose(fid);

end

%%

function res=getLength(bw)

global verNum;

addpath(genpath('BaiSkeletonPruningDCE/'));

[L Lnum]=bwlabel(bw,8);
% res: [centerRow, centerCol, length].
res=zeros(Lnum,3);

% if size(pollen,1)~=Lnum
%     fprintf(1,'pollenNum ~= Lnum!\n');
%     pause;
% end

% figure,imshow(bw);

figure;
imshow(bw);
hold on;

for i=1:Lnum
%     labelNum=L(pollen(i,1),pollen(i,2));
%     mask=L==labelNum;
    mask=L==i;
    [skel]=div_skeleton_new(4,1,~mask,verNum);
    skel=(skel~=0); % Convert the unit8 to logical.
    skel=parsiSkel(skel);
    [bbSubs bbLen bbImg tbSubs tbLen tbImg ratioInBbSubs idxLen]=getBackbone(skel,0);
%     res(i,:)=[pollen(i,1) pollen(i,2) bbLen];
    res(i,:)=[bbSubs(1,1) bbSubs(1,2) bbLen];
    
    plot(bbSubs(:,2),bbSubs(:,1),'.r','MarkerSize',1);
end

end


%% Back up.
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

