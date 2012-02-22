function branMorphProc
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

global handles debugFlag;

debugFlag=1;

% handles.widthFlag=0; % Set in the following codes.

% Specify global threshold in range [0 254].
% Problem: when skelVerNum==9, branch 115dic can only detect 1 branch.
handles.skelVerNum=30; % Skeleton Vertices number. atleast 5.
% handles.branchThre=50; % Branch skel pixel num.
% Leave off all branches shorter than 20 diagnal pixels: ceil(20*sqrt(2)).
branchThreInPixel=20;
handles.branchThre=ceil(branchThreInPixel*sqrt(2));
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

pathstr=fileparts(files{1});
% Set whether the width and bubbles should be calculated.
widthFlagFile=fullfile(pathstr,'widthFlag');
if ~exist(widthFlagFile,'file')
    infoLine=['There is no widthFlag file in current directory. '
        'If the branch width is useful for the images here, '
        'choose useWidth, otherwise noUseWidth.'];
    choice=questdlg(infoLine,'Generate widthFlag file','useWidth','notUseWidth','Cancel','notUseWidth');
    if strcmp(choice,'useWidth')
        handles.widthFlag=1;
    elseif strcmp(choice,'notUseWidth')
        handles.widthFlag=0;
    else % Cancel.
        fprintf('User canceled.');
        return;
    end
    fid=fopen(widthFlagFile,'w');
    fprintf(fid,'%g\n',handles.widthFlag~=0);
    fclose(fid);
else
    fid=fopen(widthFlagFile,'r');
    handles.widthFlag=fscanf(fid,'%d',1);
    fclose(fid);
end

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

skel=bwmorph(bw,'thin',inf);
% figure,imshow(skel);

%     skel=bwmorph(bw,'skel',inf);
%     figure,imshow(bw);
%     [skel]=div_skeleton_new(4,1,1-bw,30);

% [skel,I0,x,y,x1,y1,aa,bb]=div_skeleton_new(4,1,1-bw,60);
%     [skel]=div_skeleton_new(4,1,1-bw,handles.skelVerNum);

% skel=(skel~=0); % Convert the uint8 to logical.
skel=parsiSkel(skel);
    
% Save skeleton img.
imwrite(skel,skelFile,'png');

% [bbSubs bbLen bbImg tbSubs tbLen tbImg ratioInBbSubs idxLen]=decomposeSkel(skel,handles.pollenPos,handles.branchThre);
% [backbone branches]=decomposeSkel(skel,somabw,handles.branchThre);
% [subMatrix labelNum]=decomposeSkel(skelImg,startPoint,labelNum);
[rtMatrix startPoints]=getRtMatrix(skel,somabw,handles.branchThre,handles.widthFlag);

if debugFlag
    figure, imshow(ori);
    hold on;
    [row col]=find(skel);
    plot(col,row,'.w');
    somaPerim=bwperim(somabw,8);
    [row col]=find(somaPerim);
    plot(col,row,'.b');
    for i=1:size(startPoints,1)
        plot(startPoints(i,2),startPoints(i,1),'*r');
    end
    hold off;
end

sprintf(num2str(rtMatrix(1)));
save([handles.filenameWoExt '.rt.mat'],'rtMatrix');
clear skel;
clear somabw;

return;

end

