function pollenTubeProc
% PollenTubeProc.
% Run it as 'pollenTubeProc', then a dialogue comes out asking for image file(s);
%
%	PollenTubeProc is free software: you can redistribute it and/or modify
%	it under the terms of the GNU General Public License as published by
%	the Free Software Foundation, either version 3 of the License, or
%	(at your option) any later version.
%	
%	It is distributed in the hope that it will be useful,
%	but WITHOUT ANY WARRANTY; without even the implied warranty of
%	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%	GNU General Public License for more details.
%	
%	You should have received a copy of the GNU General Public License
%	along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
%
%	Website - https://github.com/silencej/pollenTubeProc
%
%	Copyright, 2011 Chaofeng Wang <owen263@gmail.com>

global handles debugFlag;

debugFlag=1;

% Specify global threshold in range [0 254].
handles.thre=uint8(0.1*255);
handles.skelVerNum=7; % Skeleton Vertices number. atleast 5.
handles.diskSize=50;
handles.eraseFactor=0;
handles.addFactor=2;
handles.cutMargin=10; % cut to make the result have 10 pixel margin.
% NOTE: if cutMargin is too small, i.e., <=5, then div_skeleton_new may has
% some problem, where bwperim fails.

% Result: Although the gamma transform makes the bw more connected and less
% rough, it also causes the overestimate of the circle's radius.
% gamma=1; % Used for image enhancement. Gamma transform with r<1 expands the low intensity levels in output. The lower gamma, the more washed-out of the image.

files=getImgFileNames;
if files{1}==0
    return;
end
if length(files)>1
    debugFlag=0;
    fprintf(1,'Multiple image input, thus no plot output.\n');
end

addpath(genpath('BaiSkeletonPruningDCE/'));
close all;
warning off Images:initSize:adjustingMag; % Turn off image scaling warnings.
iptsetpref('ImshowBorder','tight'); % Make imshow display no border and thus print will save no white border.

for i=1:length(files)
    procImg(files{i});
end

end

function procImg(imgFile)

global ori handles luCorner rlCorner debugFlag;

% Timer.
tic;

ori=imread(imgFile);
handles.filename=imgFile;

% Binarize images.
bw=preprocess;

%% Find the backbone.

%the shape must be black, i.e., values zero.
% Vertices num at least be 3. However, using 3 may cause "warning: matrix
% is singular to working precision." Surprisingly, 4 is also not working.
% Thus 5 is the minimum.
% Time expenditure for div_skeleton_new:
% vertices num=5: 108.20s
% vertices num=4: 107.29s
% [bw,I,x,y,x1,y1,aa,bb]=div_skeleton_new(4,1,1-bw,5);
% [skel]=div_skeleton_new(4,1,1-bw,5);
[skel]=div_skeleton_new(4,1,1-bw,handles.skelVerNum);

skel=(skel~=0); % Convert the unit8 to logical.
skel=parsiSkel(skel);

% Save skeleton img.
fullSkel=getFullBw(skel);
[pathstr, name]=fileparts(handles.filename);
skelFile=fullfile(pathstr,[name '.skel.png']);
imwrite(fullSkel,skelFile,'png');

[bbSubs bbLen bbImg tbSubs tbLen tbImg ratioInBbSubs idxLen]=getBackbone(skel,0);
clear skel;

% Timer
toc;

Idist=bwdist(~bw);
clear bw;

%% Third branch.

% tbDist=Idist.*double(tbImg);
% tbDist1=tbDist(:);
% tbProfile=tbDist1(sub2ind(size(tbImg),tbSubs(:,1),tbSubs(:,2)));

%% Output

% Find the pollen and tip radius.

% Idist=bwdist(~bw);

bbDist=Idist.*double(bbImg);
bbDist1=bbDist(:);
bbProfile=bbDist1(sub2ind(size(bbImg),bbSubs(:,1),bbSubs(:,2)));
% The length of the input x must be more than three times the filter
% order in filtfilt.
if length(bbProfile)>3*48
    winLen=48;
else
    winLen=floor(length(bbProfile)/3);
end
bbProfile=double(bbProfile);
bbProfileF=filtfilt(ones(1,winLen)/winLen,1,bbProfile);
if debugFlag
    figure;
    plot(bbProfile,'-k');
    set(gca,'TickDir','out','Box','off','YGrid','on'); % Reset axes for printing.
    set(gcf,'InvertHardCopy','off');
    hold on;
    plot(bbProfileF,'-r');
    plot([idxLen idxLen],ylim,'-b'); % branching position.
    hold off;
    legend('Unfiltered Profile','Filtered Profile','Branching Point');
    xlabel('Pixels along backbone');
    ylabel('Distance transform');
end
% Points largest bbProfiles, circleCenter = [row col distanceTransform].
[pks locs]=findpeaks(bbProfileF);
% pksS - sorted.

[pksS I]=sort(pks,'descend');
locsS=locs(I);
circleCenter(1,1:2)=bbSubs(locsS(1),:);
circleCenter(1,3)=pksS(1);
if length(locsS)>=2
    circleCenter(2,1:2)=bbSubs(locsS(2),:);
    circleCenter(2,3)=pksS(2);
end
if length(locsS)>=3
    circleCenter(3,1:2)=bbSubs(locsS(3),:);
    circleCenter(3,3)=pksS(3);
end

%     % Correct backbone length by radius.
%     bbLen=bbLen-circleCenter(1,3)-circleCenter(2,3);

% Draw circles.
if debugFlag
    luCorner=handles.luCorner;
    rlCorner=handles.rlCorner;
    figure;
    warning off Images:initSize:adjustingMag; % Turn off image scaling warnings.
    % Use warning('query','last'); to see the warning message ID.
    imshow(ori);
    % Make print the default white plotted line.
    set(gca,'Color','black');
    set(gcf,'InvertHardCopy','off');
    %		[row col]=find(bbImg);
    hold on;
    %		plot(col,row,'.w');
    % Show the backbone.
    plot(bbSubs(:,2)+luCorner(2)-1, bbSubs(:,1)+luCorner(1)-1, '.w');
    plot(tbSubs(:,2)+luCorner(2)-1, tbSubs(:,1)+luCorner(1)-1, '.w');
    % Show the main circles.
    % 		radius=int32(circleCenter(1,3));
    radius=circleCenter(1,3);
    row=circleCenter(1,1)-radius+luCorner(1)-1;
    col=circleCenter(1,2)-radius+luCorner(2)-1;
    rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','r');
    plot(col+radius,row+radius,'or'); % plot center.
    if length(locsS)>=2
        radius=circleCenter(2,3);
        row=circleCenter(2,1)-radius+luCorner(1)-1;
        col=circleCenter(2,2)-radius+luCorner(2)-1;
        rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','c');
        plot(col+radius,row+radius,'oc');
    end
    if length(locsS)>=3
        radius=circleCenter(3,3);
        row=circleCenter(3,1)-radius+luCorner(1)-1;
        col=circleCenter(3,2)-radius+luCorner(2)-1;
        rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','b');
        plot(col+radius,row+radius,'ob');
    end
    hold off;
end

fprintf(1,'Image: %s\n',handles.filename);
fprintf(1,'Backbone Euclidean Length: %6.2f pixels.\n',bbLen);
fprintf(1,'Largest radius (red circle): %6.2f pixels.\n',circleCenter(1,3));
if length(locsS)>=2
    fprintf(1,'Second largest radius (cyan circle): %6.2f pixels.\n',circleCenter(2,3));
end
if length(locsS)>=3
    fprintf(1,'Third largest radius (blue circle): %6.2f pixels.\n',circleCenter(3,3));
% else
%     fprintf(1,'There are only two peaks in backbone profile.\n');
end
fprintf(1,'Third branch length ratio in backbone: %4.2f from the left bb point in profile.\n',ratioInBbSubs);
end


function bw=preprocess
% Preprocessing.
% 1. Find the channel with highest intensity and binarize in the channel.
% 2. Find the largest connected component and erase all other foreground pixels.
% 3. Crop off to get the part containing the largest connected component. Following process will be carried on the part.
%

global handles;

%% Cut frame.
cutFrameFcn;

%% Read bw file.
hasBwFile=0;
[pathstr, name]=fileparts(handles.filename);
bwFile=fullfile(pathstr,[name '.bw.png']);
if exist(bwFile,'file')
    bwFull=imread(bwFile);
    bwFull=(bwFull~=0);
    hasBwFile=1;
    bw=getPart(bwFull);
    plotBwOnOriPart(bw);
end

%% Apply thre.

if ~hasBwFile
    % Read thre from threFile.
    % thre [-1 254].
    [pathstr, name]=fileparts(handles.filename);
    threFile=fullfile(pathstr,[name '.thre']);
    if exist(threFile,'file')
        fid=fopen(threFile,'rt');
        handles.thre=fscanf(fid,'%d');
        fclose(fid);
        if length(handles.thre)>1
            disp('pollenTubeProc: preprocess: threshold file contains more than 1 threshold.');
        end
    end    
    bw=applyThre(handles.thre);
    fprintf(1,'======================================================================\nThe present threshold is %d.\n',handles.thre);
    reply=input('If you want to reset the threshold, input here in range [0 254].\nOtherwise if the threshhold is ok, press ENTER\nAn integer or Enter: ','s');
    while ~isempty(reply)
        handles.thre=uint8(str2double(reply));
        bw=applyThre(handles.thre);
        fprintf(1,'======================================================================\nThe present threshold is %d.\n',handles.thre);
        reply=input('If you want to reset the threshold, input here in range [0 254].\nIf the threshhold is ok, press ENTER\nAn integer or Enter: ','s');
    end
end

%% Apply manual correction.

figure(handles.fH);
fprintf(1,'======================================================================\nManual correction for the bitmap.\n');
fprintf(1,'Select a region to add/erase, and double click if finished.\nIf no need to correct, just double click on image.\n');
set(handles.fH,'Name','Select a region to add/erase, and double click if finished.');
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

%% 
delete(h);
close(handles.fH);
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

[pathstr, name]=fileparts(handles.filename);
threFile=fullfile(pathstr,[name '.thre']);
fid=fopen(threFile,'w');
fprintf(fid,'%d',handles.thre);
fclose(fid);
bwFile=fullfile(pathstr,[name '.bw.png']);
bwFull=getFullBw(bw);
imwrite(bwFull,bwFile,'png');


end

function cutFrameFcn

global handles ori grayOriPart oriPart;

% Get grayOri.
img1=ori(:,:,1);
img2=ori(:,:,2);
img3=ori(:,:,3);
[mv mi]=max([max(img1(:)) max(img2(:)) max(img3(:))]);
clear img1 img2 img3;
grayOri=ori(:,:,mi);

bw=(grayOri>handles.thre);
bw=imfill(bw,'holes');
bw=(bw~=0);

% Cutting.
bw=keepLargest(bw);
[luCorner rlCorner]=getCutFrame(bw);
handles.luCorner=luCorner;
handles.rlCorner=rlCorner;

% Get other cuts.
% luRow=handles.luCorner(1);
% luCol=handles.luCorner(2);
% rlRow=handles.rlCorner(1);
% rlCol=handles.rlCorner(2);
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

bwFull=[zeros(handles.luCorner(1)-1,size(bw,2)); bw; zeros(size(ori,1)-handles.rlCorner(1),size(bw,2))];
bwFull=[zeros(size(bwFull,1),handles.luCorner(2)-1) bwFull zeros(size(bwFull,1),size(ori,2)-handles.rlCorner(2))];

end

function imgPart=getPart(img)
global handles;

luRow=handles.luCorner(1);
luCol=handles.luCorner(2);
rlRow=handles.rlCorner(1);
rlCol=handles.rlCorner(2);
imgPart=img(luRow:rlRow,luCol:rlCol,:);

end

function [luCorner rlCorner]=getCutFrame(bw)
% Find the suitable cutting frame, which is represented by left-upper and
% right-lower corner.

global handles;
cutMargin=handles.cutMargin;

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

function bw=applyThre(thre)

global grayOriPart;

bw=(grayOriPart>thre);
bw=imfill(bw,'holes');
bw=(bw~=0);

bw=keepLargest(bw);
plotBwOnOriPart(bw);

end

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