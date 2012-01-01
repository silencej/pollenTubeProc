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
handles.skelVerNum=7; % Skeleton Vertices number. atleast 5.
handles.diskSize=50;
handles.eraseFactor=0;
handles.addFactor=2;

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

% TODO:
% Detect pollen. Benefits: 1. avoid problem when branches are longest.
% 2. the profile has a start point, and the tbRatio too.
% Wildtype, swollenTip, branching, wavy, swollenTube, budding.
% SwollenTip: parralell, perpendicular.

% width of tube.

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
pollenPos=fscanf(fid,'%d', [1,2]); % pollen position: [row col].
if isempty(pollenPos)
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

%% Backbone.

[bbSubs bbLen bbImg tbSubs tbLen tbImg ratioInBbSubs idxLen]=decomposeSkel(skel,handles.pollenPos);
clear skel;
										  
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

% Pollen Width = median+1.4826*mad.
pollenWidth=median(bbProfile)+1.4826*mad(bbProfile,1);

% Get rid of all peaks lower than pollenWidth.
pks=pks(pks>pollenWidth);
locs=locs(pks>pollenWidth);

% pksS - sorted.
[pksS I]=sort(pks,'descend');
locsS=locs(I);

% Find the pollen grain circle.
grain=[0 0 0];
for i=1:length(pksS)
	if euDist(bbSubs(locsS(i),:),pollenPos)<=bbProfile(locsS(i))
		grain=[bbSubs(locsS(i),:) bbProfile(locsS(i))]; % grain: [row col radius].
		break;
	end
end
if ~grain(1)
	error('Pollen Grain Calculation Error!!!');
end

circleCenter(1,1:2)=bbSubs(locsS(1),:);
% circleCenter(1,3)=pksS(1);
% Get the original, e.g. unfiltered height!
circleCenter(1,3)=bbProfile(locsS(1));
if length(locsS)>=2
	circleCenter(2,1:2)=bbSubs(locsS(2),:);
	circleCenter(2,3)=pks(I(2));
end
if length(locsS)>=3
	circleCenter(3,1:2)=bbSubs(locsS(3),:);
	circleCenter(3,3)=pks(I(3));
end

%	 % Correct backbone length by radius.
%	 bbLen=bbLen-circleCenter(1,3)-circleCenter(2,3);

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
	plot(col+radius,row+radius,'or','MarkerSize',9); % plot center.
	if length(locsS)>=2
		radius=circleCenter(2,3);
		row=circleCenter(2,1)-radius+luCorner(1)-1;
		col=circleCenter(2,2)-radius+luCorner(2)-1;
		rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','c');
		plot(col+radius,row+radius,'.c','MarkerSize',9);
	end
	if length(locsS)>=3
		radius=circleCenter(3,3);
		row=circleCenter(3,1)-radius+luCorner(1)-1;
		col=circleCenter(3,2)-radius+luCorner(2)-1;
		rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','b');
		plot(col+radius,row+radius,'.b','MarkerSize',9);
	end
	hold off;
end

fprintf(1,'==============================================\nResult:\n');
fprintf(1,'Image: %s\n',handles.filename);
fprintf(1,'Backbone Euclidean Length: %6.2f pixels.\n',bbLen);
fprintf(1,'Largest radius (red circle): %6.2f pixels.\n',circleCenter(1,3));
if length(locsS)>=2
	fprintf(1,'Second largest radius (cyan circle): %6.2f pixels.\n',circleCenter(2,3));
end
if length(locsS)>=3
	fprintf(1,'Third largest radius (blue circle): %6.2f pixels.\n',circleCenter(3,3));
% else
%	 fprintf(1,'There are only two peaks in backbone profile.\n');
end
fprintf(1,'Third branch length ratio in backbone: %4.2f from the left bb point in profile.\n',ratioInBbSubs);
end



