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

handles.widthFlag=0; % Set whether the width and bubbles should be calculated.

% Specify global threshold in range [0 254].
% Problem: when skelVerNum==9, branch 115dic can only detect 1 branch.
handles.skelVerNum=30; % Skeleton Vertices number. atleast 5.
handles.branchThre=100; % Branch skel pixel num.
% Used to set how far away a peak should be away from branching point.
handles.peakNotBranchThre=20;
% Preset the col num for EMFM. At least 3+2=5, or 7, 9, ... 2 more each time.
handles.emfmCol=11;
% Bubble detection scale thre. Only bubbles with radius>coef*tubeWidth are
% reported.
handles.bubbleRadCoef=2;

% Result: Although the gamma transform makes the bw more connected and less
% rough, it also causes the overestimate of the circle's radius.
% gamma=1; % Used for image enhancement. Gamma transform with r<1 expands the low intensity levels in output. The lower gamma, the more washed-out of the image.

files=getImgFileNames;
% if files{1}==0
if isempty(files)
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
% Turn off noPeaks warning.
warning off signal:findpeaks:noPeaks;

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
% annoFile=[handles.filenameWoExt '.anno'];
bwFile=[handles.filenameWoExt '.bw.png'];
somabwFile=[handles.filenameWoExt '.somabw.png'];
if ~exist(cutOriFile,'file')
	fprintf(1,'%s must exist to proceed %s\n.',cutOriFile,handles.filename);
	fprintf(1,'Use preProc.m to generate it.\n');
	return;
end
%	if ~exist(annoFile,'file')
%		fprintf(1,'%s must exist to proceed %s\n.',annoFile,handles.filename);
%		fprintf(1,'Use preProc.m to generate it.\n');
%		return;
%	end
if ~exist(bwFile,'file')
	fprintf(1,'%s must exist to proceed %s\n.',bwFile,handles.filename);
	fprintf(1,'Use preProc.m to generate it.\n');
	return;
end
if ~exist(somabwFile,'file')
	fprintf(1,'%s must exist to proceed %s\n.',somabwFile,handles.filename);
	fprintf(1,'Use preProc.m to generate it.\n');
	return;
end

ori=imread(cutOriFile);
bw=imread(bwFile);
somabw=imread(somabwFile);
% figure,imshow(somabw);
% imclose the soma so it's more smooth and easy to cal the startPoints.
somabw=imclose(somabw,strel('disk',9));
% figure,imshow(somabw);

%	% Read anno file.
%	fid=fopen(annoFile,'rt');
%	firstline=fgetl(fid);
%	handles.annoVer=0;
%	if lower(firstline(1))~='v'
%		thre=str2num(firstline);
%	else
%		handles.annoVer=str2num(firstline(2:end));
%		thre=fscanf(fid,'%d',1); % useless here, but used in preproc.m.
%	end
%	sprintf('%g',thre);
%	clear thre;
%	if ~handles.annoVer % v0.
%		pollenPos=fscanf(fid,'%d', [1,2]); % pollen position: [row col].
%		sprintf('%g',pollenPos);
%		clear pollenPos;
%	end
%	%	if isempty(handles.pollenPos)
%	%		fprintf(1,'Pollen Position is not listed in anno file!\n');
%	%		fprintf(1,'Use preProc.m to generate it.\n');
%	%		return;
%	%	end
%	fclose(fid);

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

skelFile=[handles.filenameWoExt '.skel.png'];
% if exist(skelFile,'file')
% %     skel=imread(skelFile);
%     skel=bwmorph(bw,'skel',inf);
% else

%     bw=imclose(bw,strel('disk',3));
bw=imopen(bw,strel('disk',1));
bw=imclose(bw,strel('disk',5));
skel=bwmorph(bw,'thin',inf);
% figure,imshow(skel);

%     skel=bwmorph(bw,'skel',inf);
%     figure,imshow(bw);
%     [skel]=div_skeleton_new(4,1,1-bw,30);

% [skel,I0,x,y,x1,y1,aa,bb]=div_skeleton_new(4,1,1-bw,60);
%     [skel]=div_skeleton_new(4,1,1-bw,handles.skelVerNum);

    skel=(skel~=0); % Convert the uint8 to logical.
    skel=parsiSkel(skel);
    
    % Save skeleton img.
    % fullSkel=getFullBw(skel);
    % [pathstr, name]=fileparts(handles.filename);
    % resStruct.path=pathstr;
    % resStruct.filename=name;
    imwrite(skel,skelFile,'png');
% end

figure, imshow(ori);
hold on;
[row col]=find(skel);
plot(col,row,'.w');
somaPerim=bwperim(somabw,8);
[row col]=find(somaPerim);
plot(col,row,'.w');
hold off;

% [bbSubs bbLen bbImg tbSubs tbLen tbImg ratioInBbSubs idxLen]=decomposeSkel(skel,handles.pollenPos,handles.branchThre);
% [backbone branches]=decomposeSkel(skel,somabw,handles.branchThre);
% [subMatrix labelNum]=decomposeSkel(skelImg,startPoint,labelNum);
[rtMatrix]=getRtMatrix(skel,somabw,handles.branchThre,handles.widthFlag);
sprintf(rtMatrix(1));
save([handles.filenameWoExt '.rt.mat'],'rtMatrix');
clear skel;
clear somabw;

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
										  
%% Find the pollen grain and bb bubble radius.

Idist=bwdist(~bw);
clear bw;

% EMFM is the combination of bbMat and brMat;

[bbMat grain bbBubbles]=analyzeBackbone(backbone,branches,Idist,debugFlag);

if ~isempty(branches)
	[brMat brBubbles]=analyzeBranches(branches,Idist);
else
	brMat='';
	brBubbles='';
end


%% Image plot.
if debugFlag
	figure;
	warning off Images:initSize:adjustingMag; % Turn off image scaling warnings.
	% Use warning('query','last'); to see the warning message ID.
	
	% Plot the backbone width.
	bbImg=backbone.img;
	bbWimg=imdilate(bbImg,strel('disk',floor(bbMat(3))));
	bwP=bwperim(bbWimg); % perimeter binary image.
	ori1=ori(:,:,1); % ori 1 layer for temp use.
	ori1(bwP)=255;
	ori(:,:,1)=ori1;
	ori1=ori(:,:,2); % ori 1 layer for temp use.
	ori1(bwP)=255;
	ori(:,:,2)=ori1;
	ori1=ori(:,:,3); % ori 1 layer for temp use.
	ori1(bwP)=255;
	ori(:,:,3)=ori1;

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
	rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','c');
	plot(col+radius,row+radius,'.c','MarkerSize',15); % plot center.
	
	% Plot bubbles on backbone.
	for i=1:size(bbBubbles,1)
		radius=bbBubbles(i,3);
		row=bbBubbles(i,1)-radius;
		col=bbBubbles(i,2)-radius;
		rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','m');
		plot(col+radius,row+radius,'.m','MarkerSize',15); % plot center.
	end

	% Plot branches bubbles.
	for i=1:size(brBubbles,1)
		radius=brBubbles(i,3);
		row=brBubbles(i,1)-radius;
		col=brBubbles(i,2)-radius;
		rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','m');
		plot(col+radius,row+radius,'.m','MarkerSize',15); % plot center.
	end

	hold off;
	print('-dpng','-r300','-zbuffer',[handles.filenameWoExt '_res.png']);
end


%% Output to the text file filename.emfm.

emfmFile=[handles.filenameWoExt '.emfm'];
fid=fopen(emfmFile,'w');
fprintf(fid,'%g\t',bbMat');
fprintf(fid,'\n');

for i=1:size(brMat,1)
% 	fprintf(fid,'%g\t',brMat'); % fprintf is column-wise.
	fprintf(fid,'%g\t',brMat(i,:));
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

% Find the pollen grain circle.
% [row col radius idx].
grain=[0 0 0 0];
% grainLoc=0;
% pollenPos is now estimated by the pixel with largest bw-dist.
somaDist=bwdist(somabw);
[mv mi]=max(somaDist(:));
sprintf(num2str(mv));
[handles.pollenPos(1) handles.pollenPos(2)]=ind2sub(mi,size(somaDist));
for i=1:length(pks)
	if euDist(bbSubs(locs(i),:),handles.pollenPos)<=bbProfile(locs(i))
		grain=[bbSubs(locs(i),:) bbProfile(locs(i)) locs(i)]; % grain: [row col radius idx].
		grainLoc=locs(i);
		break;
	end
end
if ~grain(1)
	error('Pollen Grain Calculation Error!!!');
end

% Width = median+1.4826*mad.
% bbWidth=median(bbProfile)+1.4826*mad(bbProfile,1);
% Update: Now only use median as an estimate for tube width.
% bbWidth=median(bbProfile);
% Use median of all minima as an estimate for tube width.
[vv]=findpeaks(-bbProfileF);
vv=-vv;
% bbWidth=median(vv)+1.4826*mad(vv);
bbWidth=median(vv);

% % Get rid of all peaks lower than bbWidth.
% locs=locs(pks>bbWidth);
% pks=pks(pks>bbWidth);
% thre=median(pks)+1.4826*mad(pks,1);
% thre=median(bbProfile);
% thre=min(handles.bubbleRadCoef*bbWidth,grain(3));
thre=handles.bubbleRadCoef*bbWidth;
locs=locs(pks>thre);
pks=pks(pks>thre);

% pksS - sorted.
[pksS I]=sort(pks,'descend');
locsS=locs(I);

bbMat=zeros(1,handles.emfmCol);
bbMat(1)=grain(3);
bbMat(2)=bbLen;
bbMat(3)=bbWidth;

%% Cal branchIdx and Profile plot.

% branchIdx is used for getting peaks which are not at branching points.
% if branches is empty, length(branches) is 0, then branchIdx is empty.
branchIdx=zeros(length(branches),1);
for i=1:length(branches)
	branchIdx(i)=branches(i).bbbIdx;
end

%%

bubbleNum=0;
bubbles=zeros(5,4); % bubbles: [row col radius idx].
% Find the bubbles on backbone, ignore pollen grain and branching points.
for i=1:length(pksS)
	if locsS(i)==grainLoc
		continue;
	end
	if isempty(branchIdx) || min(abs(branchIdx-locsS(i)))>handles.peakNotBranchThre;
		gImg=bbImg;
		sp=bbSubs(1,:);
		bubblePos=bbSubs(locsS(i),:);
		[len idx]=getLenOnLine(sp,bubblePos);
		bubbleNum=bubbleNum+1;
		bubbles(bubbleNum,:)=[bubblePos bbProfile(locsS(i)) idx];
		bbMat(3+(bubbleNum-1)*2+1)=double(len/bbLen);
		bbMat(3+(bubbleNum-1)*2+2)=bbProfile(locsS(i));
	end
end

% Shrink trailing zero cols out.
ind=find(bbMat(end:-1:1));
bbMat=bbMat(1:end-ind+1);

% Shrink zero rows out from bubbles.
bubbles=bubbles(bubbles(:,1)~=0,:);

% Plot bubbles and grain on profile.
if debugFlag
	figure;
	plot(bbProfile,'-k');
	set(gca,'TickDir','out','Box','off','YGrid','on'); % Reset axes for printing.
	set(gcf,'InvertHardCopy','off');
	hold on;
	plot(bbProfileF,'-r');

	plot(grain(4),bbProfileF(grain(4)),'*c'); % grain.
	
	for i=1:size(bubbles,1)
		plot(bubbles(i,4),bbProfileF(bubbles(i,4)),'*m'); % bubbles position.
	end

	% if branches is empty, length(branches) is 0.
	for i=1:length(branches)
		plot([branches(i).bbbIdx branches(i).bbbIdx],ylim,'-b'); % branching position.
	end

	hold off;
	legend('Unfiltered Profile','Filtered Profile','Grain','Bubbles on Backbone','Branching Point');
	xlabel('Pixels along backbone');
	ylabel('Distance transform');
	print('-dpng','-r300','-zbuffer',[handles.filenameWoExt '_profile.png']);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [brMat bubbles]=analyzeBranches(branches,Idist)
% returen the branches part of the EMFM.
% bubbles: all picked bubbles on the branches. Return for ploting.

global handles gImg;

brNum=length(branches);
if ~brNum
	brMat='';
	bubbles='';
	return;
end
brMat=zeros(brNum,handles.emfmCol);

bubbleNum=0;
bubbles=zeros(10,3); % bubbles: [row col radius].

for i=1:brNum

	brImg=branches(i).img;
	brSubs=branches(i).subs;
	brLen=branches(i).len;
	
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
	
   	% Width = median+1.4826*mad.
% 	brWidth=median(brProfile)+1.4826*mad(brProfile,1);
%	 brWidth=median(brProfile);
	[vv]=findpeaks(-brProfileF);
	vv=-vv;
%	 brWidth=median(vv)+1.4826*mad(vv);
	brWidth=median(vv);
	
   	brMat(i,1)=branches(i).ratio;
	brMat(i,2)=brLen;
	brMat(i,3)=brWidth;
	
	[pks locs]=findpeaks(brProfileF);
	if isempty(pks)
		continue;
	end

	% Get rid of all peaks lower than thre.
%	 thre=median(brProfile);
	thre=handles.bubbleRadCoef*brWidth;
	locs=locs(pks>thre);
	pks=pks(pks>thre);

	% pksS - sorted.
	[pksS I]=sort(pks,'descend');
	locsS=locs(I);

	% bubbleNum is for bubbles on all branches, while bubbleOnBrNum is for one branch.
	bubbleOnBrNum=0;
	% Find the bubbles on backbone, ignore pollen grain and branching points.
	for j=1:length(pksS)
		bubbleNum=bubbleNum+1;
		bubblePos=brSubs(locsS(j),:);
		bubbles(bubbleNum,:)=[bubblePos brProfile(locsS(j))];
		bubbleOnBrNum=bubbleOnBrNum+1;
		gImg=brImg;
		sp=brSubs(1,:);
		len=getLenOnLine(sp,bubblePos);
		brMat(i,3+(bubbleOnBrNum-1)*2+1)=double(len/brLen);
		brMat(i,3+(bubbleOnBrNum-1)*2+2)=brProfile(locsS(j));
	end

end

% Shrink tailing zero cols out.
while isempty(find(brMat(:,end),1))
	brMat=brMat(:,1:end-1);
end

% Shrink zero rows out from bubbles.
bubbles=bubbles(bubbles(:,1)~=0,:);

% Shrink zero rows out from bubbles.
% 	brBubbles=brBubbles(brBubbles(:,1)~=0,:);


end

