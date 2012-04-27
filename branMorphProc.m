function branMorphProc(debugF)
% branMorphProc.
% Run it as 'branMorphProc', then a dialogue comes out asking for image file(s);
%
%	branMorphProc is free software: you can redistribute it and/or modify
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
%	along with Foobar. If not, see <http://www.gnu.org/licenses/>.
%
%	Website - https://github.com/silencej/pollenTubeProc
%
%	Copyright, 2011, 2012 Chaofeng Wang <owen263@gmail.com>

clear global;
fprintf(1,'branMorphProc is running...\n');

global handles debugFlag textOutput;

% Set a defaultScale here.
defaultScale=20;
handles.defaultScale=defaultScale;

if nargin==0
	debugFlag=0;
else
	debugFlag=debugF;
end
% The text output may be needed by users.
textOutput=1;

% Specify global threshold in range [0 254].

% handles.widthFlag=0; % Set in the following codes.

% % Used to set how far away a peak should be away from branching point.
% handles.peakNotBranchThre=20;

% Preset the col num for EMFM. At least 3+2=5, or 7, 9, ... 2 more each time.
% handles.emfmCol=11;

% The following has been set in "traceBranch.m".
% Bubble detection scale thre. Only bubbles with radius>coef*tubeWidth are
% reported.
% handles.bubbleRadCoef=2;

% Result: Although the gamma transform makes the bw more connected and less
% rough, it also causes the overestimate of the circle's radius.
% gamma=1; % Used for image enhancement. Gamma transform with r<1 expands the low intensity levels in output. The lower gamma, the more washed-out of the image.

[files flFlag]=getImgFileNames;
% files=getImgFileNames;
if isempty(files)
	return;
end

% if flFlag
%	 tempFiles=files;
%	 filesPt=0;
%	 files=cell(1,1);
%	 for i=1:length(tempFiles)
%		 fls=getFilelist(tempFiles{i}); % files.
%		 flsNum=length(fls);
%		 files(filesPt+1:filesPt+flsNum)=fls;
%		 filesPt=filesPt+flsNum;
%	 end
% end

% if length(files)>1
% 	debugFlag=0;
% 	fprintf(1,'Multiple image input, thus no plot output.\n');
% end

addpath(genpath('BaiSkeletonPruningDCE/'));
close all;
warning off Images:initSize:adjustingMag; % Turn off image scaling warnings.
iptsetpref('ImshowBorder','tight'); % Make imshow display no border and thus print will save no white border.
% Turn off noPeaks warning.
warning off signal:findpeaks:noPeaks;

pathstr=fileparts(files{1});

% noWidthFlag=0;
emptyPollenFlag=0; % Flag for whether there is pollenFlag specified.
noScale=0;
noRadius=0;
flagChanged=0;
dirFlagFile=fullfile(pathstr,'dirFlag'); % directory flags.
if ~exist(dirFlagFile,'file')
% 	noWidthFlag=1;
    emptyPollenFlag=1;
	noScale=1;
	noRadius=1;
	flagChanged=1;
else
	flags=nan(3,1);
	fid=fopen(dirFlagFile,'r');
	tline=fgetl(fid);
	pt=0;
	while ischar(tline) && ~isempty(tline)
		pt=pt+1;
		flags(pt,1)=str2double(tline);
		tline=fgetl(fid);
	end
	fclose(fid);
	if pt<1
		emptyPollenFlag=1;
	else
		handles.pollenFlag=(flags(1)~=0);
		fprintf(1,'The pollen flag = %g.\n',handles.pollenFlag);
	end
	if pt<2
		noScale=1;
	else
		handles.scale=flags(2);
		fprintf(1,'Scale = %g X.\n',handles.scale);
	end
	if pt<3
		noRadius=1;
		flagChanged=1;
	else
		handles.radius=flags(3);
		fprintf(1,'Cell Radius = %g micrometer.\n',handles.radius);
	end
end

if emptyPollenFlag
	% Pollen Flag. Set to be 1 if pollen tube images, or 0 if neurons.
	% images.
	infoLine='There is no pollenFlag setting in current directory. Please specify.';
	choice=questdlg(infoLine,'Generate dirFlag file','Pollen','Neuron','Cancel','Pollen');
	if strcmp(choice,'Pollen')
		handles.pollenFlag=1;
	elseif strcmp(choice,'Neuron')
		handles.pollenFlag=0;
	else % Cancel.
		fprintf('User canceled.');
		return;
	end
end

if noScale
	% scale.
	promptLine=sprintf('Choose a scale value (default %g X,).',defaultScale); %  0.1065 um/pixel
	choice=inputdlg(promptLine,'Scale',1,{num2str(defaultScale)});
	handles.scale=str2double(choice{1});
end

if noRadius
	% radius.
	promptLine='Choose a radius value in micrometer (default 15 for tobaco pollen).';
	choice=inputdlg(promptLine,'Scale',1,{'15'});
	handles.radius=str2double(choice{1});
end

% Save flags for the dir.
if flagChanged
	fid=fopen(dirFlagFile,'w');
	fprintf(fid,'%g\n',handles.pollenFlag~=0);
	fprintf(fid,'%g\n',handles.scale);
	fprintf(fid,'%g\n',handles.radius);
	fclose(fid);
end

% Specify whether use image thinning or Bai's method for skeletonization.
handles.useThinFlag=0;
if ~handles.pollenFlag
% handles.branchThre=50; % Branch skel pixel num.
% Leave off all branches shorter than 20 diagnal pixels: ceil(20*sqrt(2)).
	branchThreInPixel=20;
    handles.useThinFlag=1;
else
	branchThreInPixel=50;
end
handles.branchThre=ceil(branchThreInPixel*sqrt(2));

if ~handles.useThinFlag
	% % Problem: when skelVerNum==9, branch 115dic can only detect 1 branch.
	handles.skelVerNum=15; % Skeleton Vertices number. atleast 5.
end


for i=1:length(files)
	procImg(files{i});
end

% If use filelist, then makeDfm directly for you.
if flFlag
	pathname=fileparts(files{1});
	sepStr=filesep;
	% On windows, filesep should be escaped.
	if strcmp(sepStr,'\')
		sepStr='\\';
	end
	regCond=['(?<=' sepStr ')[^' sepStr ']*$'];
	dirname=regexp(pathname,regCond,'match'); % dirname is a cell string.
	makeDfm(pathname,fullfile(pathname,dirname{1}));
end

if length(files)>2
	close all;
end

helpdlg('branMorphProc finished.','Finish');

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


global ori grayOri handles debugFlag textOutput;

% sprintf(num2str(debugFlag));

% Output the current filename.
sepNum=20;
seps=repmat('=',1,sepNum);
seps=[seps '\n'];
fprintf(1,[seps 'Processing %s:\n'],imgFile);

if textOutput
tic;
end

handles.filename=imgFile;
[pathstr,name]=fileparts(imgFile);
handles.filenameWoExt=fullfile(pathstr,name);

% The following three files must exist. Use "preProc.m" to generate them.
cutOriFile=[handles.filenameWoExt '.cut.png'];
% annoFile=[handles.filenameWoExt '.anno'];
bwFile=[handles.filenameWoExt '.bw.png'];
somabwFile=[handles.filenameWoExt '.somabw.png'];
if ~exist(cutOriFile,'file')
	fprintf(1,'ERROR: %s must exist to proceed %s\n.',cutOriFile,handles.filename);
	fprintf(1,'Use preProc.m to generate it.\n');
	return;
end
%	if ~exist(annoFile,'file')
%		fprintf(1,'%s must exist to proceed %s\n.',annoFile,handles.filename);
%		fprintf(1,'Use preProc.m to generate it.\n');
%		return;
%	end
if ~exist(bwFile,'file')
	fprintf(1,'ERROR: %s must exist to proceed %s\n.',bwFile,handles.filename);
	fprintf(1,'Use preProc.m to generate it.\n');
	return;
end
if ~exist(somabwFile,'file')
	fprintf(1,'ERROR: %s must exist to proceed %s\n.',somabwFile,handles.filename);
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
% %	 skel=imread(skelFile);
%	 skel=bwmorph(bw,'skel',inf);
% else

% % If the branch is fat, use Bai's method is better.

if handles.useThinFlag
	skel=bwmorph(bw,'thin',inf);
else
% figure,imshow(skel);

%	 skel=bwmorph(bw,'skel',inf);
%	 figure,imshow(bw);
% else
% skel=div_skeleton_new(4,1,1-bw,0);
% [skel,I0,x,y,x1,y1,aa,bb]=div_skeleton_new(4,1,1-bw,60);
	skel=div_skeleton_new(4,1,1-bw,handles.skelVerNum);
end
% end

% skel=(skel~=0); % Convert the uint8 to logical.
skel=parsiSkel(skel);
	
% Save skeleton img.
imwrite(skel,skelFile,'png');

% [bbSubs bbLen bbImg tbSubs tbLen tbImg ratioInBbSubs idxLen]=decomposeSkel(skel,handles.pollenPos,handles.branchThre);
% [backbone branches]=decomposeSkel(skel,somabw,handles.branchThre);
% [subMatrix labelNum]=decomposeSkel(skelImg,startPoint,labelNum);

% if handles.widthFlag
distImg=bwdist(~bw);
% else
% 	distImg=[];
% end

%	 [rtMatrix
%	 startPoints]=getRtMatrix(skel,somabw,handles.branchThre,handles.widthFlag);

%% Plot result.

% if debugFlag
grayOri=getGrayImg(ori);
[fVec fnames rtMatrix startPoints newSkel bubbles tips lbbImg]=getRtMatrix(skel,somabw,handles.branchThre,distImg,grayOri,bw);
sprintf([num2str(fVec(1)) fnames{1}]);
% Plot the ori with longest backbone width, lbw.
% if handles.widthFlag
lbw=floor(rtMatrix(1,5));
% else
%     lbw=10;
% end
lbbWimg=imdilate(lbbImg,strel('disk',lbw));
bwP=bwperim(lbbWimg); % perimeter binary image.
ori1=ori(:,:,1); % ori 1 layer for temp use.
ori1(bwP)=255;
ori(:,:,1)=ori1;
ori1=ori(:,:,2); % ori 1 layer for temp use.
ori1(bwP)=255;
ori(:,:,2)=ori1;
ori1=ori(:,:,3); % ori 1 layer for temp use.
ori1(bwP)=255;
ori(:,:,3)=ori1;

close all; % Now only keep one figure open.
if debugFlag
	figure('Visible','on');
else
	figure('Visible','off');
end
imshow(ori,'Border','tight');
hold on;

% Plot skels.
[row col]=find(skel);
plot(col,row,'.w','Markersize',2);
[row col]=find(newSkel);
plot(col,row,'.w'); % MarkerSize=5.

% Plot soma/pollen grain.
somaPerim=bwperim(somabw,8);
[row col]=find(somaPerim);
plot(col,row,'.b');
for i=1:size(startPoints,1)
    if startPoints(i,3)
        plot(startPoints(i,2),startPoints(i,1),'*r');
    end
end

% If widthFlag is off, bubbles and tips will be empty.
for j=1:size(bubbles,1)
	radius=bubbles(j,3);
	row=bubbles(j,1)-radius;
	col=bubbles(j,2)-radius;
	rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','r');
	plot(col+radius,row+radius,'.r','MarkerSize',15); % plot center.
end
for j=1:size(tips,1)
	radius=tips(j,3);
	row=tips(j,1)-radius;
	col=tips(j,2)-radius;
	rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','m');
	plot(col+radius,row+radius,'.m','MarkerSize',15); % plot center.
end

hold off;

set(gcf,'InvertHardCopy','off');
% print([handles.filenameWoExt '.res.png'],'-dpng',sprintf('-r%d',dpi));
saveas(gcf,[handles.filenameWoExt '.res.eps'],'epsc2'); % eps level2 color.


%% Save rt.mat and fv.mat.

sprintf(fnames{1});
sprintf(num2str(rtMatrix(1)));
sprintf(num2str(fVec(1)));
save([handles.filenameWoExt '.rt.mat'],'rtMatrix');
% Note: the fVec has been scaled to the deafultScale.
save([handles.filenameWoExt '.fv.mat'],'fVec','fnames');
clear skel;
clear somabw;

%% Text output.

if textOutput
    if handles.pollenFlag
        fprintf(1,'The length of major backbone = %g pixels.\n',rtMatrix(1,4));
        fprintf(1,'The tip width of major backbone = %g pixels.\n',rtMatrix(1,6));
    end
    toc;
end

end

