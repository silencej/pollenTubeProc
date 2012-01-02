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
handles.cutFrameThre=uint8(0.1*255);
% "cutMargin" is used in:
% 1. cutFrameFcn.
% 2. Pad the bw image.
handles.cutMargin=10; % cut to make the result have 10 pixel margin.
% NOTE: if cutMargin is too small, i.e., <=5, then div_skeleton_new may has
% some problem, where bwperim fails.

% The following are used to set the manual correction sensibility.
handles.diskSize=50;
handles.eraseFactor=0;
handles.addFactor=2;
% When the mask has more pixels than maskIntelThre, the mask will be
% intelligently dilated, otherwise no dilation.
handles.maskIntelThre=400;

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

fprintf(1,'Manual Annotation is finished. Thanks for your work!\n');
end

%%%%%%%%%%%%%%%%% Proc 1 img. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function procImg(filename)

global handles ori;

handles.filename=filename;
[pathstr, name]=fileparts(filename);
% Filename Without extension.
handles.filenameWoExt=fullfile(pathstr,name);

%% Cut frame.
% Read ori image and cut it to appropriate size.
cutFrameFcn;

%% Read Anno file.

% Read thre and pollenPos from annoFile.
% thre range: [-1 254].
% [pathstr, name]=fileparts(filename);
% annoFile=fullfile(pathstr,[name '.anno']);
annoFile=[handles.filenameWoExt '.anno'];
pollenPos=[30; 30];
thre=uint8(0.2*255);
if exist(annoFile,'file')
	fid=fopen(annoFile,'rt');
	thre=fscanf(fid,'%d',1);
	oldPos=fscanf(fid,'%d', [1,2]); % pollen position: [row col].
	if ~isempty(oldPos)
		pollenPos=oldPos;
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
% [pathstr, name]=fileparts(filename);
% bwFile=fullfile(pathstr,[name '.bw.png']);
bwFile=[handles.filenameWoExt '.bw.png'];
if exist(bwFile,'file')
	bw=imread(bwFile);
	bw=(bw~=0);
	hasBwFile=1;
	% For compatibility: If the bw image is generated by previous version, it will be same as the uncut ori image. Thus it needs to be cut either.
	if size(bw,1)~=size(ori,1) || size(bw,2)~=size(ori,2)
		[luCorner rlCorner]=getCutFrame(bw,handles.cutMargin);
		bw=getPart(bw,luCorner,rlCorner);
	end
	plotBwOnOri(bw);
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
fH=handles.fH;
figure(fH);
fprintf(1,'======================================================================\nManual correction for the bitmap.\n');
fprintf(1,'Select a region to add/erase, and double click if finished.\nIf no need to correct, just double click on image.\n');
set(fH,'Name','Select a region to add/erase, and double click if finished.');
h=impoly(gca,'Closed',1);
api=iptgetapi(h);
pos=api.getPosition();
mask=poly2mask(pos(:,1),pos(:,2),size(bw,1),size(bw,2));
while ~isempty(find(mask(:), 1))
    fprintf(1,'The selected mask has %g pixels.\n',length(find(mask)));
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
% [pathstr, name]=fileparts(filename);
% annoFile=fullfile(pathstr,[name '.anno']);
fid=fopen(annoFile,'w');
fprintf(fid,'%d',thre);
fprintf(fid,'\n%g\t%g',floor(pollenPos(1)),floor(pollenPos(2)));
fclose(fid);
imwrite(bw,bwFile,'png');

end

%%%%%%%%%%%%%%%% Sub Functions. %%%%%%%%%%%%%%%%%%%%%

function cutFrameFcn
% 1. Get the global ori. If there is filename.cut.png, directly read ori from it, get grayOri and return.
% 2. Cut the global ori to appropriate size.
% 3. Get the global grayOri.
% 4. Save the cut ori as filename.cut.png.

global handles ori grayOri;

cutOriFile=[handles.filenameWoExt '.cut.png'];
if exist(cutOriFile,'file')
	ori=imread(cutOriFile);
	grayOri=getGrayImg(ori);
	return;
end

ori=imread(handles.filename);
% Get grayOri.
grayOri=getGrayImg(ori);

bw=(grayOri>handles.cutFrameThre);
bw=imfill(bw,'holes');
bw=(bw~=0);

% Cutting.
bw=keepLargest(bw);
[luCorner rlCorner]=getCutFrame(bw,handles.cutMargin);
% handles.luCorner=luCorner;
% handles.rlCorner=rlCorner;
ori=getPart(ori,luCorner,rlCorner);
% Get cut grayOri.
grayOri=getGrayImg(ori);
imwrite(ori,cutOriFile);

% Get other cuts.
% luRow=handles.luCorner(1);
% luCol=handles.luCorner(2);
% rlRow=handles.rlCorner(1);
% rlCol=handles.rlCorner(2);
% ori=ori(luRow:rlRow,luCol:rlCol,:); % oriPart for show.

% grayOriPart=grayOri(luRow:rlRow,luCol:rlCol);
% oriPart=ori(luRow:rlRow,luCol:rlCol,:); % oriPart for show.

% grayOriPart=getPart(grayOri);
% oriPart=getPart(ori);
end

%% Utility functions.

%	function bwFull=getFullBw(bw)
%	global handles ori;
%	
%	if ndims(bw)>2
%		fprintf(1,'getFullBw: bw is not two-dimensional!\n');
%		bwFull=0;
%		return;
%	end
%	
%	bwFull=[zeros(luCorner(1)-1,size(bw,2)); bw; zeros(size(ori,1)-rlCorner(1),size(bw,2))];
%	bwFull=[zeros(size(bwFull,1),luCorner(2)-1) bwFull zeros(size(bwFull,1),size(ori,2)-rlCorner(2))];
%	
%	end


%%

function bw=applyThre(thre)

global grayOri;

% grayOri=getGrayImg(ori);

bw=(grayOri>thre);
bw=imfill(bw,'holes');
bw=(bw~=0);

bw=keepLargest(bw);
plotBwOnOri(bw);

end

%%

function bw=applyMask(mask,bw)

global grayOri handles;

% grayOri=getGrayImg(ori);

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
    % If the mask is small, no intelligent dilation is used.
    if length(find(mask))<=handles.maskIntelThre
        bw=bw-andBw;
        bw=imfill(bw,'holes');
        bw=keepLargest(bw);
        plotBwOnOri(bw);
        return;
    end
	window=double(grayOri.*uint8(andBw));
	window1d=window(andBw(:)~=0);
	winThre=median(window1d)+eraseFactor*1.4826*mad(window1d,1);
	se=strel('disk',diskSize);
	bigMask=imdilate(mask,se);
	threRes=(grayOri<winThre);
	threRes=threRes & bigMask;
	threRes=threRes | mask;
	[r c]=ind2sub(size(mask),find(mask,1));
	threRes=bwselect(threRes,c,r,8);
	bw=bw - ( bw & threRes);
	% If the ROI contains mostly bw's 0s', the ROI is used to add.
else
    % If the mask is small, no intelligent dilation is used.
    if length(find(mask))<=handles.maskIntelThre
        bw=bw+minusBw;
        bw=imfill(bw,'holes');
        bw=keepLargest(bw);
        plotBwOnOri(bw);
        return;
    end
	window=double(grayOri.*uint8(minusBw));
	window1d=window(minusBw(:)~=0);
	winThre=median(window1d)-addFactor*1.4826*mad(window1d,1);
	se=strel('disk',diskSize);
	bigMask=imdilate(mask,se);
	threRes=(grayOri>winThre);
	threRes=threRes & bigMask;
	threRes=threRes | mask;
	[r c]=ind2sub(size(mask),find(mask,1));
	threRes=bwselect(threRes,c,r,8); % bwselect is odd! first c then r!!
	bw=bw | threRes;
end

bw=imfill(bw,'holes');
bw=keepLargest(bw);
plotBwOnOri(bw);

end

%%

function plotBwOnOri(bw)
global handles ori;

if ~isfield(handles,'fH') || ~ishandle(handles.fH)
	handles.fH=figure;
end

figure(handles.fH);

bwP=bwperim(bw); % perimeter binary image.

ori1=ori(:,:,1); % ori 1 layer for temp use.
ori1(bwP)=255;
oriShow(:,:,1)=ori1;
ori1=ori(:,:,2); % ori 1 layer for temp use.
ori1(bwP)=255;
oriShow(:,:,2)=ori1;
ori1=ori(:,:,3); % ori 1 layer for temp use.
ori1(bwP)=255;
oriShow(:,:,3)=ori1;
imshow(oriShow);
end

%%

function plotPollen(pos)

global handles ori;

if ~isfield(handles,'fH') || ~ishandle(handles.fH)
	handles.fH=figure;
end

figure(handles.fH);

imshow(ori);
hold on;
plot(pos(2),pos(1),'dr','MarkerEdgeColor','r','MarkerFaceColor','c','MarkerSize',9);
hold off;

end

%%