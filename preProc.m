function preProc
% Preprocessing.
% Directly run "preProc".
% 1. Find the channel with highest intensity and binarize in the channel.
% 2. Find the largest connected component and erase all other foreground pixels.
% 3. Crop off to get the part containing the largest connected component. Following process will be carried on the part.
%

% Clear previous global handles.
clear global;
global handles;

% This thre is used to cut frame.
handles.thre=uint8(0.1*255);
handles.cutMargin=10; % cut to make the result have 10 pixel margin.
% NOTE: if cutMargin is too small, i.e., <=5, then div_skeleton_new may has
% some problem, where bwperim fails.

files=getImgFileNames;
if files{1}==0
	return;
end

close all;
warning off Images:initSize:adjustingMag; % Turn off image scaling warnings.
iptsetpref('ImshowBorder','tight'); % Make imshow display no border and thus print will save no white border.

for i=1:length(files)
	procImg(files{i});
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function procImg(filename)

global ori handles luCorner rlCorner debugFlag;

ori=imread(filename);
handles.filename=filename;

%% Cut frame.
cutFrameFcn;

%% Read Anno file.

% Read thre and pollenPos from annoFile.
% thre [-1 254].
[pathstr, name]=fileparts(filename);
annoFile=fullfile(pathstr,[name '.anno']);
if exist(annoFile,'file')
	fid=fopen(annoFile,'rt');
	thre=fscanf(fid,'%d',1);
	oldPos=fscanf(fid,'%d', [1,2]); % pollen position: [row col].
	if ~isempty(oldPos)
		pollenPos=oldPos;
	else
		pollenPos=[30; 30];
	end
	fclose(fid);
	if length(thre)>1
		disp('preProc: anno file contains more than 1 threshold.');
	end
end

%% Adjust pollenPos.

plotPollen(pollenPos);
fprintf(1,'----------------------------------------------------------------------\nThe present pollenPos is %d %d.\n',pollenPos(1),pollenPos(2));
fprintf(1,'If you want to reset the pollen indicator, left click in the image.\nOtherwise if the position is ok, right click on the image.\n');
[col row button]=ginput(1);
% 1,2,3: left, middle, right.
while button~=3
	plotPollen([row col]);
	pollenPos(1)=row;
	pollenPos(2)=col;
	fprintf(1,'----------------------------------------------------------------------\nThe present pollenPos is %d %d.\n',pollenPos(1),pollenPos(2));
	fprintf(1,'If you want to reset the pollen indicator, left click in the image.\nOtherwise if the position is ok, right click on the image.\n');
	[col row button]=ginput(1);
end
% pollenPos=[row; col];

%% Read bw file.
hasBwFile=0;
[pathstr, name]=fileparts(filename);
bwFile=fullfile(pathstr,[name '.bw.png']);
if exist(bwFile,'file')
	bwFull=imread(bwFile);
	bwFull=(bwFull~=0);
	hasBwFile=1;
	bw=getPart(bwFull);
	plotBwOnOriPart(bw);
end

%% Adjust thre.

if ~hasBwFile
	bw=applyThre(thre);
	fprintf(1,'======================================================================\nThe present threshold is %d.\n',thre);
	reply=input('If you want to reset the threshold, input here in range [0 254].\nOtherwise if the threshhold is ok, press ENTER\nAn integer or Enter: ','s');
	while ~isempty(reply)
		thre=uint8(str2double(reply));
		bw=applyThre(thre);
		fprintf(1,'======================================================================\nThe present threshold is %d.\n',thre);
		reply=input('If you want to reset the threshold, input here in range [0 254].\nIf the threshhold is ok, press ENTER\nAn integer or Enter: ','s');
	end
end

%% Adjust mask.

figure(fH);
fprintf(1,'======================================================================\nManual correction for the bitmap.\n');
fprintf(1,'Select a region to add/erase, and double click if finished.\nIf no need to correct, just double click on image.\n');
set(fH,'Name','Select a region to add/erase, and double click if finished.');
h=impoly(gca,'Closed',1);
api=iptgetapi(h);
pos=api.getPosition();
mask=poly2mask(pos(:,1),pos(:,2),size(bw,1),size(bw,2));
while ~isempty(find(mask(:), 1))
	bw=applyMask(mask,bw);
	fprintf(1,'======================================================================\nManual correction for the bitmap.\n');
	fprintf(1,'Select a region of interest, modify, and double click if finished. If no need to correct, just double click.\n');
	h=impoly(gca,'Closed',1);
	api=iptgetapi(h);
	pos=api.getPosition();
	mask=poly2mask(pos(:,1),pos(:,2),size(bw,1),size(bw,2));
end

%% Finish Manual Anno.

delete(h);
close(fH);
fprintf(1,'User correction finished. Now processing, please wait...\n');

% Find the largest connected component, again.
bw=keepLargest(bw);

%% Clear border.
% If there is image border pixel with 1, which is to say, the largest
% connected component touches the border or even protrudes outside, which
% causes problem for DSE skeletonization.

% Directly clear the pixels in the range of cutMargin.
cutMargin=handles.cutMargin;
bw(1:cutMargin,:)=0;
bw(end-cutMargin+1:end,:)=0;
bw(:,1:cutMargin)=0;
bw(:,end-cutMargin+1:end)=0;

%% Save to file.
[pathstr, name]=fileparts(filename);
annoFile=fullfile(pathstr,[name '.anno']);
fid=fopen(annoFile,'w');
fprintf(fid,'%d',thre);
fprintf(fid,'\n%g\t%g',floor(pollenPos(1)),floor(pollenPos(2)));
fprintf(fid,'\n%g\t%g\t');
fclose(fid);
bwFile=fullfile(pathstr,[name '.bw.png']);
bwFull=getFullBw(bw);
imwrite(bwFull,bwFile,'png');

end

function cutFrameFcn

global handles ori grayOriPart oriPart;

% Get grayOri.
grayOri=getGrayImg(ori);

bw=(grayOri>handle.thre);
bw=imfill(bw,'holes');
bw=(bw~=0);

% Cutting.
bw=keepLargest(bw);
[luCorner rlCorner]=getCutFrame(bw);
handles.luCorner=luCorner;
handles.rlCorner=rlCorner;

% Get other cuts.
% luRow=luCorner(1);
% luCol=luCorner(2);
% rlRow=rlCorner(1);
% rlCol=rlCorner(2);
% grayOriPart=grayOri(luRow:rlRow,luCol:rlCol);
% oriPart=ori(luRow:rlRow,luCol:rlCol,:); % oriPart for show.
grayOriPart=getPart(grayOri);
oriPart=getPart(ori);
end

%% Utility functions.

function bwFull=getFullBw(bw)
global handles ori;

if ndims(bw)>2
	fprintf(1,'getFullBw: bw is not two-dimensional!\n');
	bwFull=0;
	return;
end

bwFull=[zeros(luCorner(1)-1,size(bw,2)); bw; zeros(size(ori,1)-rlCorner(1),size(bw,2))];
bwFull=[zeros(size(bwFull,1),luCorner(2)-1) bwFull zeros(size(bwFull,1),size(ori,2)-rlCorner(2))];

end

function imgPart=getPart(img)

luRow=luCorner(1);
luCol=luCorner(2);
rlRow=rlCorner(1);
rlCol=rlCorner(2);
imgPart=img(luRow:rlRow,luCol:rlCol,:);

end

function [luCorner rlCorner]=getCutFrame(bw)
% Find the suitable cutting frame, which is represented by left-upper and
% right-lower corner.

% luRow
for j=1:size(bw,1)
	res=find(bw(j,:), 1);
	if ~isempty(res)
		luRow=j;
		break;
	end
end
% luCol
for j=1:size(bw,2)
	res=find(bw(:,j), 1);
	if ~isempty(res)
		luCol=j;
		break;
	end
end
% rlRow
for j=luRow:size(bw,1)
	res=find(bw(j,:), 1);
	if isempty(res)
		rlRow=j;
		break;
	end
end
% rlCol
for j=luCol:size(bw,2)
	res=find(bw(:,j), 1);
	if isempty(res)
		rlCol=j;
		break;
	end
end

imgWidth=size(bw,2);
imgHeight=size(bw,1);

if luRow-cutMargin>0
	luRow=luRow-cutMargin;
end
if luCol-cutMargin>0
	luCol=luCol-cutMargin;
end
if rlRow+cutMargin<=imgHeight
	rlRow=rlRow+cutMargin;
end
if rlCol+cutMargin<=imgWidth
	rlCol=rlCol+cutMargin;
end

luCorner=[luRow luCol];
rlCorner=[rlRow rlCol];
end

%%

function bw=applyThre(thre)

global grayOriPart;

bw=(grayOriPart>thre);
bw=imfill(bw,'holes');
bw=(bw~=0);

bw=keepLargest(bw);
plotBwOnOriPart(bw);

end

%%

function bw=applyMask(mask,bw)

global grayOriPart handles;

diskSize=handles.diskSize;
eraseFactor=handles.eraseFactor;
addFactor=handles.addFactor;

mask=(mask~=0);
andBw=mask.*bw;
andBw=(andBw~=0);
minusBw=mask.*(~bw);
minusBw=(minusBw~=0);
% If the ROI contains mostly bw's 1s', the ROI is used to erase.
if length(find(andBw(:)))>=length(find(minusBw(:)))
	window=double(grayOriPart.*uint8(andBw));
	window1d=window(andBw(:)~=0);
	winThre=median(window1d)+eraseFactor*1.4826*mad(window1d,1);
	se=strel('disk',diskSize);
	bigMask=imdilate(mask,se);
	threRes=(grayOriPart<winThre);
	threRes=threRes & bigMask;
	threRes=threRes | mask;
	[r c]=ind2sub(size(mask),find(mask,1));
	threRes=bwselect(threRes,c,r,8);
	bw=bw - ( bw & threRes);
	% If the ROI contains mostly bw's 0s', the ROI is used to add.
else
	window=double(grayOriPart.*uint8(minusBw));
	window1d=window(minusBw(:)~=0);
	winThre=median(window1d)-addFactor*1.4826*mad(window1d,1);
	se=strel('disk',diskSize);
	bigMask=imdilate(mask,se);
	threRes=(grayOriPart>winThre);
	threRes=threRes & bigMask;
	threRes=threRes | mask;
	[r c]=ind2sub(size(mask),find(mask,1));
	threRes=bwselect(threRes,c,r,8); % bwselect is odd! first c then r!!
	bw=bw | threRes;
end

bw=imfill(bw,'holes');
bw=keepLargest(bw);
plotBwOnOriPart(bw);

end

%%

function plotBwOnOriPart(bw)
global handles oriPart;

if ~isfield(handles,'fH') || ~ishandle(handles.fH)
	handles.fH=figure;
end

figure(handles.fH);

bwP=bwperim(bw); % perimeter binary image.

oriPart1=oriPart(:,:,1); % oriPart 1 layer for temp use.
oriPart1(bwP)=255;
oriPartShow(:,:,1)=oriPart1;
oriPart1=oriPart(:,:,2); % oriPart 1 layer for temp use.
oriPart1(bwP)=255;
oriPartShow(:,:,2)=oriPart1;
oriPart1=oriPart(:,:,3); % oriPart 1 layer for temp use.
oriPart1(bwP)=255;
oriPartShow(:,:,3)=oriPart1;
imshow(oriPartShow);
end
