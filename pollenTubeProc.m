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

global ori cutMargin handles luCorner rlCorner;

% Specify global threshold in range (0 1).
handles.gThre=uint8(0.1*255);

% if gThre>=1 || gThre<=0
%     error('pollenTubeProc: User should specify global threshold in range (0 1).');
% end

debugFlag=1;
cutMargin=10; % cut to make the result have 10 pixel margin.
% NOTE: if cutMargin is too small, i.e., <=5, then div_skeleton_new may has
% some problem, where bwperim fails.

% Result: Although the gamma transform makes the bw more connected and less
% rough, it also causes the overestimate of the circle's radius.
% gamma=1; % Used for image enhancement. Gamma transform with r<1 expands the low intensity levels in output. The lower gamma, the more washed-out of the image.

files=getImgFileNames;
if files{1}==0
    return;
end

addpath(genpath('BaiSkeletonPruningDCE/'));
close all;
iptsetpref('ImshowBorder','tight'); % Make imshow display no border and thus print will save no white border.

for i=1:length(files)
	% Timer.
    if debugFlag
        tic;
    end
	ori=imread(files{i});
    handles.filename=files{i};
    
	% Binarize images.
	[luCorner,rlCorner,bw]=preprocess;

%% Find the backbone.

% Matlab newer version is required!
%	 CC=bwconncomp(bw,4);
%	 for j=1:CC.NumObjects
%		 ll=length(CC.PixelIdxList{j});
%	 end
%	 [mv mi]=max(ll);
%	 bw=zeros(size(bw));
%	 bw(CC.PixelIdxList{mi})=1;
%	 bw=(bw~=0);

	%the shape must be black, i.e., values zero.
	% [bw,I,x,y,x1,y1,aa,bb]=div_skeleton_new(4,1,1-bw,5);
	[skel]=div_skeleton_new(4,1,1-bw,5);
    
%     figure,imshow(bw);
	
	% Vertices num at least be 3. However, using 3 may cause "warning: matrix
	% is singular to working precision." Surprisingly, 4 is also not working.
	% Thus 5 is the minimum.
	% Time expenditure for div_skeleton_new:
	% vertices num=5: 108.20s
	% vertices num=4: 107.29s
	
	skel=(skel~=0); % Convert the unit8 to logical.
%	 imwrite(bw,'im1Skel.png','png');
%	 bw=imread('im1Skel.png');
	% imshow(bw);
	% imshow(bw+I);
	skel=parsiSkel(skel);
    
%     figure,imshow(skel);
    
	[bbSubs bbLen bbImg]=getBackbone(skel,0);
    clear skel;
	% Timer
    if debugFlag
	toc;
    end

%% Find the pollen and tip radius.

	Idist=bwdist(~bw);
	clear bw;
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
		figure, plot(bbProfile,'-k');
        hold on;
        plot(bbProfileF,'-r');
        hold off;
        legend('Unfiltered Profile','Filtered Profile');
	end
% Points largest bbProfiles, circleCenter = [row col distanceTransform].
    [pks locs]=findpeaks(bbProfileF);
    % pksS - sorted.

    [pksS I]=sort(pks,'descend');
    locsS=locs(I);
	circleCenter(1,1:2)=bbSubs(locsS(1),:);
	circleCenter(1,3)=pksS(1);
	circleCenter(2,1:2)=bbSubs(locsS(2),:);
	circleCenter(2,3)=pksS(2);
    if length(locsS)>=3
	circleCenter(3,1:2)=bbSubs(locsS(3),:);
	circleCenter(3,3)=pksS(3);
    end
    
%     % Correct backbone length by radius.
%     bbLen=bbLen-circleCenter(1,3)-circleCenter(2,3);

	% Draw circles.
    if debugFlag
        figure;
        warning off Images:initSize:adjustingMag; % Turn off image scaling warnings.
        % Use warning('query','last'); to see the warning message ID.
        imshow(ori);
        %		[row col]=find(bbImg);
        hold on;
        %		plot(col,row,'.w');
        % Show the backbone.
        plot(bbSubs(:,2)+luCorner(2)-1, bbSubs(:,1)+luCorner(1)-1, '.w');
        % Show the main circles.
        % 		radius=int32(circleCenter(1,3));
        radius=circleCenter(1,3);
        row=circleCenter(1,1)-radius+luCorner(1)-1;
        col=circleCenter(1,2)-radius+luCorner(2)-1;
        rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','r');
        radius=circleCenter(2,3);
        row=circleCenter(2,1)-radius+luCorner(1)-1;
        col=circleCenter(2,2)-radius+luCorner(2)-1;
        rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','c');
        if length(locsS)>=3
        radius=circleCenter(3,3);
        row=circleCenter(3,1)-radius+luCorner(1)-1;
        col=circleCenter(3,2)-radius+luCorner(2)-1;
        rectangle('Position',[col row 2*radius 2*radius],'Curvature',[1 1],'EdgeColor','b');
        end
        hold off;
    end

    fprintf(1,'Image: %s\n',files{i});
    fprintf(1,'Backbone Euclidean Length: %6.2f pixels.\n',bbLen);
    fprintf(1,'Largest radius (red circle): %6.2f pixels.\n',circleCenter(1,3));
    fprintf(1,'Second largest radius (cyan circle): %6.2f pixels.\n',circleCenter(2,3));
    if length(locsS)>=3
        fprintf(1,'Third largest radius (blue circle): %6.2f pixels.\n',circleCenter(3,3));
    else
        fprintf(1,'There are only two peaks in backbone profile.\n');
    end
end

end

function bw=plotThreResult

global handles grayOri ori;

luRow=handles.luCorner(1);
luCol=handles.luCorner(2);
rlRow=handles.rlCorner(1);
rlCol=handles.rlCorner(2);

grayOriPart=grayOri(luRow:rlRow,luCol:rlCol); % ori for show.
bw=(grayOriPart>handles.thre);
bw=imfill(bw,'holes');
bw=(bw~=0);
warning off Images:initSize:adjustingMag; % Turn off image scaling warnings.

if ~isfield(handles,'fH') || ~ishandle(handles.fH)
    handles.fH=figure;
end
figure(handles.fH);

bwP=bwperim(bw); % perimeter binary image.
% bw=bw(luRow:rlRow,luCol:rlCol);
oriShow=ori(luRow:rlRow,luCol:rlCol,:); % ori for show.
oriShow1=oriShow(:,:,1); % oriShow 1 layer for temp use.
oriShow1(bwP)=255;
oriShow(:,:,1)=oriShow1;
oriShow1=oriShow(:,:,2); % oriShow 1 layer for temp use.
oriShow1(bwP)=255;
oriShow(:,:,2)=oriShow1;
oriShow1=oriShow(:,:,3); % oriShow 1 layer for temp use.
oriShow1(bwP)=255;
oriShow(:,:,3)=oriShow1;
imshow(oriShow);

end

function [luCorner rlCorner bw]=preprocess
% Preprocessing.
% 1. Find the channel with highest intensity and binarize in the channel.
% 2. Find the largest connected component and erase all other foreground pixels.
% 3. Crop off to get the part containing the largest connected component. Following process will be carried on the part.
%

global ori grayOri handles cutMargin;

img1=ori(:,:,1);
img2=ori(:,:,2);
img3=ori(:,:,3);
[mv1 mi1]=max([max(img1(:)) max(img2(:)) max(img3(:))]);
clear img1 img2 img3;
grayOri=ori(:,:,mi1);

% Enhancement.
% img=imadjust(img,[double(min(img(:)))/255.0 double(max(img(:)))/255.0],[]);

% Unsharping doesn't work well.
% H=fspecial('unsharp');
% img=imfilter(img,H);

% imgNoZero=img(img>5);

% % 1. Otsu's method.
% thre=255*graythresh(img);

% Read thre from threFile.
% thre [-1 254].
[pathstr, name]=fileparts(handles.filename);
threFile=fullfile(pathstr,[name '.thre']);
if exist(threFile,'file')
    fid=fopen(threFile,'rt');
    thre=fscanf(fid,'%d');
    fclose(fid);
    if length(thre)>1
        disp('pollenTubeProc: preprocess: threshold file contains more than 1 threshold.');
    end
else
    thre=handles.gThre;
end
handles.thre=thre;

% thre=thre*255;
bw=(grayOri>handles.thre);
bw=imfill(bw,'holes');
bw=(bw~=0);

% Find the largest connected component.
[L,Num]=bwlabeln(bw,4);
ll=zeros(Num,1);
for j=1:Num
	ll(j)=length(find(L==j));
end
[mv mi]=max(ll);
bw=(L==mi);


%% Cut
% Find the suitable cutting frame, which is represented by left-upper and right-lower corner.
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

imgWidth=size(ori,2);
imgHeight=size(ori,1);

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
handles.luCorner=luCorner;
handles.rlCorner=rlCorner;

bw=plotThreResult;
fprintf(1,'======================================================================\nThe present threshold is %d.\n',handles.thre);
reply=input('If you want to reset the threshold, input here in range [0 254].\nOtherwise if the threshhold is ok, press ENTER\nAn integer or Enter: ','s');
while ~isempty(reply)
    handles.thre=uint8(str2double(reply));
    bw=plotThreResult;
    fprintf(1,'======================================================================\nThe present threshold is %d.\n',handles.thre);
    reply=input('If you want to reset the threshold, input here in range [0 254].\nIf the threshhold is ok, press ENTER\nAn integer or Enter: ','s');
end

close(handles.fH);

% Find the largest connected component, again.
[L,Num]=bwlabeln(bw,4);
ll=zeros(Num,1);
for j=1:Num
	ll(j)=length(find(L==j));
end
[mv mi]=max(ll);
bw=(L==mi);


%% Clear border.
% If there is image border pixel with 1, which is to say, the largest
% connected component touches the border or even protrudes outside, which
% causes problem for DSE skeletonization.

% Directly clear the pixels in the range of cutMargin.
bw(1:cutMargin,:)=0;
bw(end-cutMargin+1:end,:)=0;
bw(:,1:cutMargin)=0;
bw(:,end-cutMargin+1:end)=0;

% Under such condition, extra 0 pixels are added on the border.
% res=find(bw(1,:),1);
% if ~isempty(res)
%     bw=[zeros(cutMargin,size(bw,2)); bw];
% end
% res=find(bw(end,:),1);
% if ~isempty(res)
%     bw=[bw; zeros(cutMargin,size(bw,2))];
% end
% res=find(bw(:,1),1);
% if ~isempty(res)
%     bw=[zeros(size(bw,1),cutMargin) bw];
% end
% res=find(bw(:,end),1);
% if ~isempty(res)
%     bw=[bw zeros(size(bw,1),cutMargin)];
% end

%% Save to thre file.

[pathstr, name]=fileparts(handles.filename);
threFile=fullfile(pathstr,[name '.thre']);
fid=fopen(threFile,'w');
fprintf(fid,'%d',handles.thre);
fclose(fid);

% The bw still has small white spots.
% the fid to write threFile is invalid.

end

