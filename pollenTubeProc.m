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
%	Copyright, 2011, 2012 Chaofeng Wang <owen263@gmail.com>

clear global;
global handles debugFlag;

debugFlag=1;

% Specify global threshold in range [0 254].
% Problem: when skelVerNum==9, branch 115dic can only detect 1 branch.
handles.skelVerNum=11; % Skeleton Vertices number. atleast 5.
handles.branchThre=100; % Branch skel pixel num.
% Used to set how far away a peak should be away from branching point.
handles.peakNotBranchThre=20;
% Preset the col num for EMFM. At least 3+2=5, or 7, 9, ... 2 more each time.
handles.emfmCol=11;

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

%%%%%%%%%%%% Proc 1 image. %%%%%%%%%%%%%%%%

function procImg(imgFile)
% resStruct is a struct:
% path, filename, bbLen, bubbles, tbLen, tbRatio, bbProfile, tbProfile, 
% bubbles is an array:
% [centerRow centerCol radius]

% Output:
% Extensible Morphology Feature Matrix (EMFM)
% Line 1 - backbone: pollenGrainRadius, tubeLength, tubeWidth, 1stBubbleRelativePos, 1stBubbleRadius, 2ndBubbleRelativePos, ... ...
% Line 2,3,... - other branches.
% branchingRelativePos, tubeLength, tubeWidth, 1stBubbleRelativePos, ... ...
%

% TODO:
% Get Eu-distances for 3 different demo images.
% 1. Clustering on a group of simulated images. 2. Linear regression to get coef for each feature. 3. Cal the mahalonobis-distance.
%

% Wildtype, swollenTip, branching, wavy, swollenTube, budding.
% SwollenTip: parralell, perpendicular.


global ori handles debugFlag;

handles.filename=imgFile;
[pathstr,name]=fileparts(imgFile);
handles.filenameWoExt=fullfile(pathstr,name);

% The following three files must exist. Use "preProc.m" to generate them.
cutOriFile=[handles.filenameWoExt '.cut.png'];
annoFile=[handles.filenameWoExt '.anno'];
bwFile=[handles.filenameWoExt '.bw.png'];
if ~exist(cutOriFile,'file')
	fprintf(1,'%s must exist to proceed %s\n.',cutOriFile,handles.filename);
	fprintf(1,'Use preProc.m to generate it.\n');
	return;
end
if ~exist(annoFile,'file')
	fprintf(1,'%s must exist to proceed %s\n.',annoFile,handles.filename);
	fprintf(1,'Use preProc.m to generate it.\n');
	return;
end
if ~exist(bwFile,'file')
	fprintf(1,'%s must exist to proceed %s\n.',bwFile,handles.filename);
	fprintf(1,'Use preProc.m to generate it.\n');
	return;
end

ori=imread(cutOriFile);
bw=imread(bwFile);
% Read anno file.
fid=fopen(annoFile,'rt');
thre=fscanf(fid,'%d',1); % useless here.
clear thre;
handles.pollenPos=fscanf(fid,'%d', [1,2]); % pollen position: [row col].
if isempty(handles.pollenPos)
	fprintf(1,'Pollen Position is not listed in anno file!\n');
	fprintf(1,'Use preProc.m to generate it.\n');
	return;
end
fclose(fid);

%% Skeletonization.

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

skel=(skel~=0); % Convert the uint8 to logical.
skel=parsiSkel(skel);

% Save skeleton img.
% fullSkel=getFullBw(skel);
% [pathstr, name]=fileparts(handles.filename);
% resStruct.path=pathstr;
% resStruct.filename=name;
skelFile=[handles.filenameWoExt '.skel.png'];
imwrite(skel,skelFile,'png');

%% Get backbone and branches.

% [bbSubs bbLen bbImg tbSubs tbLen tbImg ratioInBbSubs idxLen]=decomposeSkel(skel,handles.pollenPos,handles.branchThre);
[backbone branches]=decomposeSkel(skel,handles.pollenPos,handles.branchThre);
clear skel;
										  
%% Find the pollen grain and bb bubble radius.

Idist=bwdist(~bw);
clear bw;

% EMFM is the combination of bbMat and brMat;

[bbMat grain bbBubbles]=analyzeBackbone(backbone,branches,Idist,debugFlag);

[brMat brBubbles]=analyzeBranches(branches,Idist);


%% Image plot.
if debugFlag
	figure;
	warning off Images:initSize:adjustingMag; % Turn off image scaling warnings.
	% Use warning('query','last'); to see the warning message ID.
	imshow(ori);
	% Make print the default white plotted line.
	set(gca,'Color','black');
	set(gcf,'InvertHardCopy','off');
	hold on;
    
    bbSubs=backbone.subs;
	
	% Plot the backbone.
	plot(bbSubs(:,2), bbSubs(:,1), '.w');
	plot(bbSubs(:,2), bbSubs(:,1), '.w');
	
	% Plot branches.
	for i=1:length(branches)
		plot(branches(i).subs(:,2), branches(i).subs(:,1), '.w'); % branching position.
	end

	% Plot grain circle.
	radius=grain(3);
	row=grain(1)-radius;
	col=grain(2)-radius;
	rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','r');
	plot(col+radius,row+radius,'.r','MarkerSize',15); % plot center.
	
	% Plot bubbles on backbone.
	for i=1:size(bbBubbles,1)
		radius=bbBubbles(3);
		row=bbBubbles(1)-radius;
		col=bbBubbles(2)-radius;
		rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','m');
		plot(col+radius,row+radius,'.m','MarkerSize',15); % plot center.
	end

	% Plot branches bubbles.
	% Shrink zero rows out from bubbles.
	brBubbles=brBubbles(brBubbles(:,1)~=0,:);
	for i=1:size(brBubbles,1)
		radius=brBubbles(3);
		row=brBubbles(1)-radius;
		col=brBubbles(2)-radius;
		rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','m');
		plot(col+radius,row+radius,'.m','MarkerSize',15); % plot center.
	end

	hold off;
end


%% Output to the text file filename.emfm.

emfmFile=[handles.filenameWoExt '.emfm'];
fid=fopen(emfmFile,'w');
fprintf(fid,'%g\t',bbMat');
fprintf(fid,'\n');

for i=size(brMat,1)
	fprintf(fid,'%g\t',brMat'); % fprintf is column-wise.
	fprintf(fid,'\n');
end

fclose(fid);

fprintf(1,'Image %s processing finished.\n',handles.filename);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [bbMat grain bubbles]=analyzeBackbone(backbone,branches,Idist,debugFlag)

global handles gImg;

bbImg=backbone.img;
bbSubs=backbone.subs;
bbLen=backbone.len;

bbDist=Idist.*double(bbImg);
bbDist=bbDist(:);
bbProfile=bbDist(sub2ind(size(bbImg),bbSubs(:,1),bbSubs(:,2)));
% The length of the input x must be more than three times the filter
% order in filtfilt.
if length(bbProfile)>3*48
	winLen=48;
else
	winLen=floor(length(bbProfile)/3);
end
bbProfile=double(bbProfile);
bbProfileF=filtfilt(ones(1,winLen)/winLen,1,bbProfile);

% Points largest bbProfiles, circleCenter = [row col distanceTransform].
[pks locs]=findpeaks(bbProfileF);

% Width = median+1.4826*mad.
bbWidth=median(bbProfile)+1.4826*mad(bbProfile,1);

% Get rid of all peaks lower than bbWidth.
locs=locs(pks>bbWidth);
pks=pks(pks>bbWidth);

% pksS - sorted.
[pksS I]=sort(pks,'descend');
locsS=locs(I);

% Find the pollen grain circle.
grain=[0 0 0];
grainIdx=0;
for i=1:length(pksS)
	if euDist(bbSubs(locsS(i),:),handles.pollenPos)<=bbProfile(locsS(i))
		grain=[bbSubs(locsS(i),:) bbProfile(locsS(i))]; % grain: [row col radius].
		grainIdx=i;
		break;
	end
end
if ~grain(1)
	error('Pollen Grain Calculation Error!!!');
end

bbMat=zeros(1,handles.emfmCol);
bbMat(1)=grain(3);
bbMat(2)=bbLen;
bbMat(3)=bbWidth;


%% Cal branchIdx and Profile plot.

% branchIdx is used for getting peaks which are not at branching points.
branchIdx=zeros(length(branches),1);
if debugFlag
	figure;
	plot(bbProfile,'-k');
	set(gca,'TickDir','out','Box','off','YGrid','on'); % Reset axes for printing.
	set(gcf,'InvertHardCopy','off');
	hold on;
	plot(bbProfileF,'-r');
	for i=1:length(branches)
		branchIdx(i)=branches(i).bbbIdx;
		plot([branches(i).bbbIdx branches(i).bbbIdx],ylim,'-b'); % branching position.
	end
	hold off;
	legend('Unfiltered Profile','Filtered Profile','Branching Point');
	xlabel('Pixels along backbone');
	ylabel('Distance transform');
end

%%

bubbleNum=0;
bubbles=zeros(5,3); % bubbles: [row col radius].
% Find the bubbles on backbone, ignore pollen grain and branching points.
for i=1:length(pksS)
	if i==grainIdx
		continue;
	end
	if min(abs(branchIdx-locsS(i)))>handles.peakNotBranchThre;
		bubbleNum=bubbleNum+1;
		bubblePos=bbSubs(locsS(i),:);
		bubbles(bubbleNum,:)=[bubblePos bbProfile(locsS(i))];
		gImg=bbImg;
		sp=bbSubs(1);
		len=getLenOnLine(sp,bubblePos);
		bbMat(i,3+(bubbleNum-1)*2+1)=double(len/bbLen);
		bbMat(i,3+(bubbleNum-1)*2+2)=bbProfile(locsS(i));
	end
end

% Shrink zero rows out from bubbles.
bubbles=bubbles(bubbles(:,1)~=0,:);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [brMat bubbles]=analyzeBranches(branches,Idist)
% returen the branches part of the EMFM.
% bubbles: all picked bubbles on the branches. Return for ploting.

global handles gImg;

brNum=length(branches);
brMat=zeros(brNum,handles.emfmCol);

bubbleNum=0;
bubbles=zeros(10,3); % bubbles: [row col radius].

for i=1:brNum

	brImg=branches(i).img;
	brSubs=branches(i).subs;

	brDist=Idist.*double(brImg);
	brDist=brDist(:);
	brProfile=brDist(sub2ind(size(brImg),brSubs(:,1),brSubs(:,2)));
	% The length of the input x must be more than three times the filter
	% order in filtfilt.
	if length(brProfile)>3*48
		winLen=48;
	else
		winLen=floor(length(brProfile)/3);
	end
	brProfile=double(brProfile);
	brProfileF=filtfilt(ones(1,winLen)/winLen,1,brProfile);

	[pks locs]=findpeaks(brProfileF);

	% Width = median+1.4826*mad.
	brWidth=median(brProfile)+1.4826*mad(brProfile,1);

	% Get rid of all peaks lower than brWidth.
	locs=locs(pks>brWidth);
	pks=pks(pks>brWidth);

	% pksS - sorted.
	[pksS I]=sort(pks,'descend');
	locsS=locs(I);

	brMat(i,1)=branches(i).ratio;
	brMat(i,2)=brLen;
	brMat(i,3)=brWidth;

	% bubbleNum is for bubbles on all branches, while bubbleOnBrNum is for one branch.
	bubbleOnBrNum=0;
	% Find the bubbles on backbone, ignore pollen grain and branching points.
	for j=1:length(pksS)
		bubbleNum=bubbleNum+1;
		bubblePos=brSubs(locsS(j),:);
		bubbles(bubbleNum,:)=[bubblePos brProfile(locsS(j))];
		bubbleOnBrNum=bubbleOnBrNum+1;
		gImg=branches(i).img;
		sp=brSubs(1);
		len=getLenOnLine(sp,bubblePos);
		brMat(i,3+(bubbleOnBrNum-1)*2+1)=double(len/brLen);
		brMat(i,3+(bubbleOnBrNum-1)*2+2)=brProfile(locsS(j));
	end

end

% Shrink zero cols out.
while isempty(find(brMat(:,end),1))
	brMat=brMat(:,1:end-1);
end

% Shrink zero rows out from bubbles.
bubbles=bubbles(bubbles(:,1)~=0,:);

end

