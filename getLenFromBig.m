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

