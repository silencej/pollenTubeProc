function preProc
% Preprocessing.
% Directly run "preProc".
% 1. Find the channel with highest intensity and binarize in the channel.
% 2. Find the largest connected component and erase all other foreground pixels.
% 3. Crop off to get the part containing the largest connected component. Following process will be carried on the part.
%

% Clear previous global handles.
clear global;
fprintf(1,'PreProc is running...\n');
global handles;

% handles.claheFlag=1;
% % If the pollen image, with has high SNR, no CLAHE is used.
% % The usage of CLAHE causes trouble for Intensity features of pollen.
% if handles.pollenFlag
%     handles.claheFlag=0;
% end

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
handles.maskIntelThre=700;
% Initials.
handles.luCorner=[0 0];
handles.rlCorner=[0 0];

% [files flFlag]=getImgFileNames;
files=getImgFileNames;
if isempty(files)
	return;
end

% if flFlag
%     tempFiles=files;
%     filesPt=0;
%     files=cell(1,1);
%     for i=1:length(tempFiles)
%         fls=getFilelist(tempFiles{i}); % files.
%         flsNum=length(fls);
%         files(filesPt+1:filesPt+flsNum)=fls;
%         filesPt=filesPt+flsNum;
%     end
% end

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

global handles ori grayOri;

% % This thre is used to cut frame.
% And this should be initialized to empty for each image, then otsu's
% threshold will be applied first.
% handles.cutFrameThre=uint8(0.08*255);
handles.cutFrameThre=[];

handles.filename=filename;
[pathstr, name]=fileparts(filename);
% Filename Without extension.
handles.filenameWoExt=fullfile(pathstr,name);


%% Read Anno file.

annoMatFile=[handles.filenameWoExt '.anno.mat'];
mc=[];
if exist(annoMatFile,'file')
    load(annoMatFile,'mc');
end

% Read thre and pollenPos from annoFile.
% thre range: [-1 254].
% [pathstr, name]=fileparts(filename);
% annoFile=fullfile(pathstr,[name '.anno']);
annoFile=[handles.filenameWoExt '.anno'];
% pollenPos=[floor(size(ori,1)); floor(size(ori,2)/2)];
% thre=uint8(0.2*255);
oriThre=0; % thre will be default to otsu's threshold later on.
handles.annoVer=0;
handles.hasAnnoFile=0;
if exist(annoFile,'file')
    handles.hasAnnoFile=1;
	fid=fopen(annoFile,'rt');
	firstline=fgetl(fid);
	if lower(firstline(1))~='v'
		oriThre=str2double(firstline);
	else
		handles.annoVer=str2double(firstline(2:end));
		oriThre=fscanf(fid,'%d',1);
		handles.cutFrameThre=fscanf(fid,'%d',1);
		handles.luCorner=fscanf(fid,'%d',[2 1]);
		handles.rlCorner=fscanf(fid,'%d',[2 1]);
        if isempty(handles.luCorner)
            handles.luCorner=[0 0];
        end
        if isempty(handles.rlCorner)
            handles.rlCorner=[0 0];
        end
	end
	fclose(fid);
	if length(oriThre)>1
		disp('preProc: anno file contains more than 1 threshold.');
	end
end

%% Cut frame.
% Read ori image and cut it to appropriate size.
cutFrameFcn;

% %% Adjust pollenPos.
% 
% plotPollen(pollenPos);
% fprintf(1,'----------------------------------------------------------------------\nThe present pollenPos is %d %d.\n',pollenPos(1),pollenPos(2));
% fprintf(1,'If you want to reset the pollen indicator, left click in the image.\nOtherwise if the position is ok, right click on the image.\n');
% [col row button]=ginput(1);
% % 1,2,3: left, middle, right.
% while button~=3
% 	plotPollen([row col]);
% 	pollenPos(1)=row;
% 	pollenPos(2)=col;
% 	fprintf(1,'----------------------------------------------------------------------\nThe present pollenPos is %d %d.\n',pollenPos(1),pollenPos(2));
% 	fprintf(1,'If you want to reset the pollen indicator, left click in the image.\nOtherwise if the position is ok, right click on the image.\n');
% 	[col row button]=ginput(1);
% end
% % pollenPos=[row; col];

%% Get bw.

% Read bw file.
% [pathstr, name]=fileparts(filename);
% bwFile=fullfile(pathstr,[name '.bw.png']);
bwFile=[handles.filenameWoExt '.bw.png'];

useOldBw=0;
% Ask if use the old bw image.
if handles.useOldCrop && handles.hasAnnoFile && exist(bwFile,'file')
    infoline=sprintf('PreProc found old bw image. Use the old one?');
    choice=questdlg(infoline,'Use old bw image','Yes','No','Cancel','Yes');
    
    if strcmp(choice,'Cancel')
        fprintf(1,'User canceled.');
        return;
    end
    if strcmp(choice,'Yes')
        bw=imread(bwFile);
        bw=(bw~=0);
        % For compatibility: If the bw image is generated by previous version, it will be same as the uncut ori image. Thus it needs to be cut either.
        if size(bw,1)~=size(ori,1) || size(bw,2)~=size(ori,2)
%             [luCorner rlCorner]=getCutFrame(bw,handles.cutMargin);
%             bw=getPart(bw,luCorner,rlCorner);
%             handles.luCorner=luCorner;
%             handles.rlCorner=rlCorner;
            error('Existing cut image has different size with the bw image!');
        end
        plotBwOnOri(bw);
        useOldBw=1;
    end
end

if ~useOldBw
    
% Adjust thre.
    % If thre is 0, then it defaults to be otsu's.
    if ~oriThre
        oriThre=graythresh(grayOri)*255;
    end
    bw=applyThre(oriThre);
    set(handles.fH,'Name','Global Thresholding');
    infoLine=sprintf('The present threshold is %d.\nIf you want to reset the threshold, input in range [0 254].\nOtherwise if the threshhold is ok, press OK.',oriThre);
    reply=inputdlg(infoLine,'Global Thresholding',1);
    reply=reply{1};
    while ~isempty(reply)
        oriThre=uint8(str2double(reply));
        bw=applyThre(oriThre);
        infoLine=sprintf('The present threshold is %d.\nIf you want to reset the threshold, input in range [0 254].\nOtherwise if the threshhold is ok, press OK.',oriThre);
        reply=inputdlg(infoLine,'Global Thresholding',1);
        reply=reply{1};
    end
end


%% Adjust mask.
bw=adjustMask(bw);

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

fprintf(1,'User correction finished. Now processing, please wait...\n');

imwrite(bw,bwFile,'png');

%% Save to file.
% [pathstr, name]=fileparts(filename);
% annoFile=fullfile(pathstr,[name '.anno']);
fid=fopen(annoFile,'w');
fprintf(fid,'v1'); % Version 1 anno file.
fprintf(fid,'\n%d',oriThre);
% pollenPos=[0 0]; % It's of no use now.
% fprintf(fid,'\n%g\t%g',floor(pollenPos(1)),floor(pollenPos(2)));
handles.cutFrameThre=0;
fprintf(fid,'\n%d',handles.cutFrameThre);
fprintf(fid,'\n%g\t%g',floor(handles.luCorner(1)),floor(handles.luCorner(2)));
fprintf(fid,'\n%g\t%g',floor(handles.rlCorner(1)),floor(handles.rlCorner(2)));
fclose(fid);


%% Obtain the soma/pollenGrain bw image.
fprintf(1,'Now spcify soma/pollenGrain for %s.\n',handles.filenameWoExt);

% somafile='';
% if ~isempty(mc)
%     somafile=mc.somafile;
% else
%     infoLine=sprintf('Use the current image %s to get soma/grain?',handles.filenameWoExt); % If no, the user need to specify another image file for soma.
%     choice=questdlg(infoLine,'Use current image to find soma','Yes','No','Cancel','Yes');
%     if strcmp(choice,'Cancel')
%         fprintf(1,'User canceled.');
%         return;
%     end
%     % if isempty(reply)
%     % 	reply='n';
%     % end
%     % reply=lower(reply);
%     % while ~strcmp(reply,'y') && ~strcmp(reply,'n')
%     % 	fprintf(1,'The input is not y or n! Please input again.\n');
%     % 	reply=input('Does the image have soma or grain image? (y/n [n]): ','s');
%     % 	if isempty(reply)
%     % 		reply='n';
%     % 	end
%     % 	reply=lower(reply);
%     % end
%     
%     % If there exists a good soma image, use it. If no good soma image, then
%     % use the original image and obtain the soma by increasing threshold to get
%     % the brightest region, which is usually where soma exists.
%     if strcmp(choice,'No')
%     end
% end

% if ~isempty(somafile)
% 	% ori and grayOri are now the cutFrame soma images, the same size with the cut image.
% 	ori=imread(somafile);
%     luCorner=handles.luCorner;
%     rlCorner=handles.rlCorner;
% 	ori=ori(luCorner(1):rlCorner(1),luCorner(2):rlCorner(2),:);
% 	grayOri=getGrayImg(ori);
% end

somaBwFile=[handles.filenameWoExt '.somabw.png'];
handles.useOldSoma=0;
if exist(somaBwFile,'file')
    bw=imread(somaBwFile);
    handles.useOldSoma=1;
    if size(bw,1)~=size(grayOri,1) || size(bw,2)~=size(grayOri,2)
%         if isempty(mc)
            bw=[];
            handles.useOldSoma=0;
%         else
%             bw=bw(mc.luCorner(1):mc.rlCorner(1),mc.luCorner(2):mc.rlCorner(2),:);
%         end
    end
end

if handles.useOldSoma
    plotBwOnOri(bw);
else
    if ~isempty(mc)
        somaThre=mc.somaThre;
    else
%         somaThre=graythresh(grayOri)*255;
        somaThre=max(grayOri(:))*0.8;
    end
    bw=applyThre(somaThre);

    set(handles.fH,'Name','Global Thresholding for Soma/Pollen grain');
    infoLine=sprintf('The present threshold is %d.\nIf you want to reset the threshold, input in range [0 254].\nOtherwise if the threshhold is ok, press OK.',somaThre);
    reply=inputdlg(infoLine,'Global Thresholding for Soma/Pollen grain',1);
    reply=reply{1};
    while ~isempty(reply)
        somaThre=uint8(str2double(reply));
        bw=applyThre(somaThre);
        infoLine=sprintf('The present threshold is %d.\nIf you want to reset the threshold, input in range [0 254].\nOtherwise if the threshhold is ok, press OK.',somaThre);
        reply=inputdlg(infoLine,'Global Thresholding for Soma/Pollen grain',1);
        reply=reply{1};
    end

end

% Ask if reset the region.
infoline=sprintf('Sometimes the thresholded region doesnot contain soma/pollen. Reset if it is the case. Reset?');
choice=questdlg(infoline,'Reset Dialog','Reset','No, keep this','Cancel','No, keep this');
if strcmp(choice,'Cancel')
    fprintf(1,'User canceled.');
    return;
end
if strcmp(choice,'Reset')
% Add first mask.
    bw=addFirstSoma;
end

bw=adjustMask(bw);

imwrite(bw,somaBwFile,'png');

% Manual operation on the bw image.

% fH=handles.fH;
% figure(fH);
% fprintf(1,'======================================================================\nManually specify the soma/pollenGrain.\n');
% fprintf(1,'Select a region for the soma/pollenGrain. It should be a little bigger.\n');
% %	 set(fH,'Name','Select a region to add/erase, and double click if finished.');
% h=impoly(gca,'Closed',1);
% api=iptgetapi(h);
% pos=api.getPosition();
% mask=poly2mask(pos(:,1),pos(:,2),size(bw,1),size(bw,2));
% imwrite(mask,somaBwFile,'png');
% end

%% Write anno mat file.
% New: the annotation will be written to mat-file.
% Mat-file Content structure: mc.
mc.version='v2';
mc.oriThre=oriThre;
mc.cutFrameThre=handles.cutFrameThre;
mc.luCorner=floor(handles.luCorner);
mc.rlCorner=floor(handles.rlCorner);
mc.somabwfile=somaBwFile;
if ~exist('somaThre','var')
    somaThre=255;
end
mc.somaThre=somaThre;
save(annoMatFile,'mc');

% Finish Manual Anno.
close(handles.fH);

end

%%%%%%%%%%%%%%%% Sub Functions. %%%%%%%%%%%%%%%%%%%%%

function cutFrameFcn
% 1. Get the global ori. If there is filename.cut.png, directly read ori from it, get grayOri and return.
% 2. Cut the global ori to appropriate size.
% 3. Get the global grayOri.
% 4. Save the cut ori as filename.cut.png.

global handles ori grayOri;

addpath('./myLee');

cutOriFile=[handles.filenameWoExt '.cut.png'];
handles.useOldCrop=0;
if handles.hasAnnoFile && exist(cutOriFile,'file')
    
    infoline=sprintf('PreProc found old cut image. Use the old one?');
    choice=questdlg(infoline,'Use old cut image','Yes','No','Cancel','Yes');
    
    if strcmp(choice,'Cancel')
        fprintf(1,'User canceled.');
        return;
    end
    if strcmp(choice,'Yes')
        ori=imread(cutOriFile);
        grayOri=getGrayImg(ori);
        handles.useOldCrop=1;
        
        % Ori image enhancement.
        enhanceProc;
        return;
    end
end

ori=imread(handles.filename);

% if handles.claheFlag
%     [grayOri rgbChan]=getGrayImg(ori);
%     grayOri=adapthisteq(grayOri); % CLAHE.
%     ori(:,:,rgbChan)=grayOri;
% else
    % Get grayOri.
grayOri=getGrayImg(ori);
% end

% Thresholding and Cutting.
if isempty(handles.cutFrameThre) || ~handles.cutFrameThre
%     % Check if the input is binary mask image.
%     if islogical(grayOri)
%         handles.cutFrameThre=0;
%     else
        handles.cutFrameThre=graythresh(grayOri)*255;
%     end
end
bw=(grayOri>handles.cutFrameThre);
bw=imfill(bw,'holes');
bw=(bw~=0);
bw=keepLargest(bw);
[luCorner rlCorner]=getCutFrame(bw,handles.cutMargin);
[luCorner rlCorner]=plotCutFrame(luCorner,rlCorner);

% handles.cutFrameThre=thre;
handles.luCorner=luCorner;
handles.rlCorner=rlCorner;

ori=getPart(ori,luCorner,rlCorner);
% Get cut grayOri.
grayOri=getGrayImg(ori);
imwrite(ori,cutOriFile);

enhanceProc;

end

%% Utility functions.

function enhanceProc

global grayOri ori;

winSize=9;
grayOri=myLee(grayOri,winSize);
grayOri=adapthisteq(grayOri);
grayOri=imadjust(grayOri,stretchlim(grayOri));
ori=ind2rgb(grayOri,jet(256));

end

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
% bw=(bw~=0);
bw=keepLargest(bw);

% Bw image smoothing.
bw=imopen(bw,strel('disk',1));
bw=imclose(bw,strel('disk',5));

bw=imfill(bw,'holes');

plotBwOnOri(bw);

end

%%

function bw=adjustMask(bw)
global handles;

fH=handles.fH;
figure(fH);
fprintf(1,'======================================================================\nManual correction for the bitmap.\n');
fprintf(1,'Select a region to add/erase, and double click if finished.\nIf no need to correct, just double click on image.\n');
set(fH,'Name','Select a region, double click if finished.');
h=impoly(gca,'Closed',1);
api=iptgetapi(h);
pos=api.getPosition();
mask=poly2mask(pos(:,1),pos(:,2),size(bw,1),size(bw,2));
while ~isempty(find(mask(:), 1))
	fprintf(1,'The selected mask has %g pixels.\n',length(find(mask)));
% 	bw=applyMask(mask,bw);
    bw=applyMask(mask,bw);
	fprintf(1,'======================================================================\nManual correction for the bitmap.\n');
	fprintf(1,'Select a region of interest, modify, and double click if finished. If no need to correct, just double click.\n');
	h=impoly(gca,'Closed',1);
	api=iptgetapi(h);
	pos=api.getPosition();
	mask=poly2mask(pos(:,1),pos(:,2),size(bw,1),size(bw,2));
end

delete(h);

end


function bw=applyMask(mask,bw)
%% New version, including:
% 1. otsu's threshold.
% 2. Dialog for add/delete.
% 3. Edit backwards.

global grayOri;
% handles;

bwBak=bw;

mask=(mask~=0);
andBw=mask & bw;
andBw=(andBw~=0);
minusBw=mask & (~bw);
% minusBw=(minusBw~=0);

addFlag=1;
% If the ROI contains mostly bw's 1s', the ROI is initially used to delete.
if length(find(andBw(:)))>=length(find(minusBw(:)))
    addFlag=0;
end

if addFlag
    whatStr='background';
    doStr='Add';
    sIdx=1;
else
    whatStr='foreground';
    doStr='Delete';
    sIdx=2;
end
infoline=sprintf('You have chosen mostly %s pixels. Do %s?',whatStr,doStr);
% choice=questdlg(infoline,'Addition/Deletion','Add','Delete','AddWoAI','De
% leteWoAI',doStr);
selection=listdlg('listString',{'Add','Delete','AddWoAI','DeleteWoAI'},'SelectionMode','single','InitialValue',sIdx,'Name','Addition/Deletion','PromptString',infoline,'listSize',[160,200]);
% if strcmp(choice,'Cancel')
%     bw=[];
%     return;
aiFlag=1;
% if strcmp(choice,'AddWoAI')
if selection==3
    bw=bw|mask;
    aiFlag=0;
% elseif strcmp(choice,'Add')
elseif selection==1
    addFlag=1;
% elseif strcmp(choice,'Delete')
elseif selection==2
    addFlag=0;
else % DeleteWoAI
    bw=bw-andBw;
    aiFlag=0;
end

if aiFlag
    if addFlag
        % window=uint8(grayOri.*uint8(mask));
        window=uint8(grayOri.*uint8(minusBw));
        windowContent=window(minusBw);
    else
        window=uint8(grayOri.*uint8(andBw));
        windowContent=window(andBw);
    end
    
    conLen=length(windowContent);
    if mod(conLen,2)
        windowContent=windowContent(1:end-1);
    end
    windowContent2=reshape(windowContent,floor(conLen/2),2);
    otsuThre=graythresh(windowContent2);
    % staThre=median(windowContent2(:))-3*1.4826*mad(windowContent2(:),1);
    
    % oldFh=gcf;
    % figure,imhist(windowContent2);
    % axis tight;
    % hold on;
    % plot([otsuThre*255 otsuThre*255],ylim,'-r');
    % % plot([staThre staThre],ylim,'-k');
    % hold off;
    %
    % figure(oldFh);
    
    thre=otsuThre;
    
    if addFlag
        threWin=im2bw(window,thre);
        %     threWin=window>staThre;
        %     figure,imshow(threWin);
        
        threWin=imopen(threWin,strel('disk',1));
        threWin=imclose(threWin,strel('disk',5));
        
        bw=bw | threWin;
    else
        threWin=~im2bw(window,thre) & mask;
        
        threWin=imopen(threWin,strel('disk',1));
        threWin=imclose(threWin,strel('disk',5));
        
        bw=bw-(bw&threWin);
    end
end

% bw=imfill(bw,'holes');
bw=keepLargest(bw);

% % Bw image smoothing.
% bw=imopen(bw,strel('disk',1));
% bw=imclose(bw,strel('disk',5));

bw=imfill(bw,'holes');

plotBwOnOri(bw);

infoline='Is this modification acceptable?';
choice=questdlg(infoline,'Backwards/Keep Change','GoBack','KeepChange','KeepChange');
if strcmp(choice,'GoBack')
    bw=bwBak;
    plotBwOnOri(bw);
end

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
ori1(bwP)=0;
oriShow(:,:,1)=ori1;
ori1=ori(:,:,2); % ori 1 layer for temp use.
ori1(bwP)=0;
oriShow(:,:,2)=ori1;
ori1=ori(:,:,3); % ori 1 layer for temp use.
ori1(bwP)=0;
oriShow(:,:,3)=ori1;
imshow(oriShow);
end

%%
function [luCorner,rlCorner]=plotCutFrame(luCorner,rlCorner)

global handles ori;

if ~isfield(handles,'fH') || ~ishandle(handles.fH)
	handles.fH=figure;
    set(handles.fH,'Name',handles.filenameWoExt);
end

figure(handles.fH);

imshow(ori);
% hold on;
% rectangle('Position',[luCorner(2) luCorner(1) rlCorner(2)-luCorner(2)
% rlCorner(1)-luCorner(1)],'LineWidth',3,'LineStyle','--','EdgeColor','r');

% Use imrect instead.
h=imrect(gca, [luCorner(2) luCorner(1) rlCorner(2)-luCorner(2) rlCorner(1)-luCorner(1)]);
fprintf(1,'Pause now awaiting for user interaction...\n');
pause;
fprintf(1,'Cut frame is done.\n');

api = iptgetapi(h);
rectPos=api.getPosition();
delete(h);

% hold off;

luCorner(2)=floor(rectPos(1));
luCorner(1)=floor(rectPos(2));
rlCorner(2)=floor(rectPos(3)+rectPos(1));
rlCorner(1)=floor(rectPos(4)+rectPos(2));
end

function bw=addFirstSoma

% global handles;
global ori;

imshow(ori);
h=impoly(gca,'Closed',1);
api=iptgetapi(h);
pos=api.getPosition();
delete(h);
bw=poly2mask(pos(:,1),pos(:,2),size(ori,1),size(ori,2));
% Smoothing.
bw=imopen(bw,strel('disk',1));
bw=imclose(bw,strel('disk',5));

plotBwOnOri(bw);

end

%%

% function plotPollen(pos)
% 
% global handles ori;
% 
% if ~isfield(handles,'fH') || ~ishandle(handles.fH)
% 	handles.fH=figure;
% end
% 
% figure(handles.fH);
% 
% imshow(ori);
% hold on;
% plot(pos(2),pos(1),'dr','MarkerEdgeColor','r','MarkerFaceColor','c','MarkerSize',9);
% hold off;
% 
% end

%%

% function bw=applyMask(mask,bw)
% 
% global grayOri handles;
% 
% diskSize=handles.diskSize;
% eraseFactor=handles.eraseFactor;
% addFactor=handles.addFactor;
% 
% mask=(mask~=0);
% andBw=mask & bw;
% andBw=(andBw~=0);
% minusBw=mask & (~bw);
% minusBw=(minusBw~=0);
% % If the ROI contains mostly bw's 1s', the ROI is used to erase.
% if length(find(andBw(:)))>=length(find(minusBw(:)))
% 	% If the mask is small, no intelligent dilation is used.
%     mLen=length(find(mask));
%     intelFlag=0;
%     if mLen>handles.maskIntelThre
%         infoline=sprintf('You have chosen %g pixels. Do intelligent dilation?',mLen);
%         choice=questdlg(infoline,'Intelligent Dilation','Do','Dont','Dont');
%         if strcmp(choice,'Do')
%             intelFlag=1;
%         end
%     end
%     if ~intelFlag
%         bw=bw-andBw;
%         bw=imfill(bw,'holes');
%         bw=keepLargest(bw);
%         plotBwOnOri(bw);
%         return;
%     end
% 	window=double(grayOri.*uint8(andBw));
% 	window1d=window(andBw(:)~=0);
% 	winThre=median(window1d)+eraseFactor*1.4826*mad(window1d,1);
% 	se=strel('disk',diskSize);
% 	bigMask=imdilate(mask,se);
% 	threRes=(grayOri<winThre);
% 	threRes=threRes & bigMask;
% 	threRes=threRes | mask;
% 	[r c]=ind2sub(size(mask),find(mask,1));
% 	threRes=bwselect(threRes,c,r,8);
% 	bw=bw - ( bw & threRes);
% 	% If the ROI contains mostly bw's 0s', the ROI is used to add.
% else
%     % If the mask is small, no intelligent dilation is used.
%     mLen=length(find(mask));
%     intelFlag=0;
%     if mLen>handles.maskIntelThre
%         infoline=sprintf('You have chosen %g pixels. Do intelligent dilation?',mLen);
%         choice=questdlg(infoline,'Intelligent Dilation','Do','Dont','Dont');
%         if strcmp(choice,'Do')
%             intelFlag=1;
%         end
%     end
%     if ~intelFlag
%         bw=bw+minusBw;
%         bw=imfill(bw,'holes');
%         bw=keepLargest(bw);
%         plotBwOnOri(bw);
%         return;
%     end
% 	window=double(grayOri.*uint8(minusBw));
% 	window1d=window(minusBw(:)~=0);
% 	winThre=median(window1d)-addFactor*1.4826*mad(window1d,1);
% 	se=strel('disk',diskSize);
% 	bigMask=imdilate(mask,se);
% 	threRes=(grayOri>winThre);
% 	threRes=threRes & bigMask;
% 	threRes=threRes | mask;
% 	[r c]=ind2sub(size(mask),find(mask,1));
% 	threRes=bwselect(threRes,c,r,8); % bwselect is odd! first c then r!!
% 	bw=bw | threRes;
% end
% 
% bw=imfill(bw,'holes');
% bw=keepLargest(bw);
% plotBwOnOri(bw);
% 
% end