function bw=tileSeg(imgIn)

len=60;
img=imgIn;

rowNum=size(imgIn,1);
colNum=size(imgIn,2);
bw=zeros(rowNum,colNum);
rowItr=floor(rowNum/len);
colItr=floor(colNum/len);

for i=1:rowItr
    for j=1:colItr
        rowRange=[(i-1)*len+1 i*len];
        colRange=[(i-1)*len+1 i*len];
        if i==rowItr
            rowRange=[(i-1)*len+1 rowNum];
        end
        if j==colItr
            colRange=[(i-1)*len+1 colNum];
        end
        imgPart=img(rowRange(1):rowRange(2),colRange(1):colRange(2));
        bw(rowRange(1):rowRange(2),colRange(1):colRange(2))=im2bw(imgPart,graythresh(imgPart));
    end
end

end