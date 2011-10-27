function pollenTubeProc(gThre)
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

% User specify global threshold in range (0 1).
if nargin==0
    gThre=0.2;
end
if gThre>=1 || gThre<=0
    error('pollenTubeProc: User should specify global threshold in range (0 1).');
end

global ori cutMargin;

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

for i=1:length(files)
	% Timer.
    if debugFlag
	tic;
    end
	ori=imread(files{i});
	% Binarize images.
	[luCorner,rlCorner,bw]=preprocess(gThre);

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

function [luCorner,rlCorner,bw]=preprocess(gThre)
% Preprocessing.
% 1. Find the channel with highest intensity and binarize in the channel.
% 2. Find the largest connected component and erase all other foreground pixels.
% 3. Crop off to get the part containing the largest connected component. Following process will be carried on the part.

global ori cutMargin;

imgWidth=size(ori,2);
imgHeight=size(ori,1);

img1=ori(:,:,1);
img2=ori(:,:,2);
img3=ori(:,:,3);
[mv1 mi1]=max([max(img1(:)) max(img2(:)) max(img3(:))]);
clear img1 img2 img3;
img=ori(:,:,mi1);

% Enhancement.
% img=imadjust(img,[double(min(img(:)))/255.0 double(max(img(:)))/255.0],[]);

% Unsharping doesn't work well.
% H=fspecial('unsharp');
% img=imfilter(img,H);

% imgNoZero=img(img>5);

% % 1. Otsu's method.
% thre=255*graythresh(img);

% The following falied!! Since the histograms of different images differ a
% lot!
% % histogram simple threshold, which is the first peak after the maximal peak - background - in histogram.
% [counts x]=imhist(img);
% dcounts=diff(counts);
% thre=x(find(dcounts>=0,1))+1;

thre=gThre*255;
img=(img>thre);

img=imfill(img,'holes');
bw=(img~=0);
clear img;

% Find the largest connected component.
[L,Num]=bwlabeln(bw,4);
ll=zeros(Num,1);
for j=1:Num
	ll(j)=length(find(L==j));
end
[mv mi]=max(ll);
bw=(L==mi);

% If there is image border pixel with 1, which is to say, the largest
% connected component touches the border or even protrudes outside, which
% causes problem for DSE skeletonization.
% Under such condition, extra 0 pixels are added on the border.
res=find(bw(1,:),1);
if ~isempty(res)
    bw=[zeros(cutMargin,size(bw,2)); bw];
end
res=find(bw(end,:),1);
if ~isempty(res)
    bw=[bw; zeros(cutMargin,size(bw,2))];
end
res=find(bw(:,1),1);
if ~isempty(res)
    bw=[zeros(size(bw,1),cutMargin) bw];
end
res=find(bw(:,end),1);
if ~isempty(res)
    bw=[bw zeros(size(bw,1),cutMargin)];
end

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
bw=bw(luRow:rlRow,luCol:rlCol);

% % Don't give any much help if the halo problem is not serious.
% % Thresholding with Otsu's method again in a more confined scope.
% imgPart=ori(:,:,mi1);
% imgPart=imgPart(luRow:rlRow,luCol:rlCol);
% 
% thre=255*graythresh(imgPart);
% bw=(imgPart>thre);
% bw=imfill(bw,'holes');
% bw=(bw~=0);


% % Dehalo: Fail in generality.
% % ridge finding.
% fWindowLen=5;
% imgPartS=imfilter(imgPart,fspecial('gaussian',[fWindowLen fWindowLen],1));
% imgRidge=ridgeFind(imgPartS,21,10);
% clear imgPartS;
% res=imgPart.*uint8(imgRidge);
% res=(res>255*graythresh(res(res>0)));
% res=connectNbr(res);
% bw=imfill(res,'holes');
% bw=(bw~=0);


end

%% 

% It=imread('im1Bw.png');
% Idist=bwdist(~It);
% Iskeldist=Idist.*double(bbImg);
% bbInt=bbImg(find(Iskeldist~=0));
% bbInt=Iskeldist(find(Iskeldist~=0));
% mean(bbInt)
% ans =
%	82.0784
% ito=imopen(It,strel('disk',82));
% thre=mean(bbInt)+std(bbInt);
% thre
% thre =
%   115.1093
% ito=imopen(It,strel('disk',115));
% figure,imshow(ito);
