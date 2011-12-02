function getLenFromBig

global rowTileNum colTileNum;

% Parameters.
rowTileNum=7;
colTileNum=7;

files=getImgFileNames;
if files{1}==0
    return;
end
if length(files)>1
    fprintf(1,'Multiple image input, thus no plot output.\n');
    return;
end

img=imread(files);
grayImg=getGrayImg(img);
bw=otsuThreImg(img);

bw=clearTileBorder(bw);

end

function bw=otsuThreImg(img)

bw=(img>255*graythresh(img));

end

function bw=cleanTileBorder(bw)

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



end
