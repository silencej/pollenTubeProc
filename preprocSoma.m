function preprocSoma

% Clear previous globals.
clear global;
fprintf(1,'PreProcSoma is running...\n');

[files flFlag]=getImgFileNames;
if isempty(files)
	return;
end

if flFlag
    tempFiles=files;
    filesPt=0;
    files=cell(1,1);
    for i=1:length(tempFiles)
        fls=getFilelist(tempFiles{i}); % files.
        flsNum=length(fls);
        files(filesPt+1:filesPt+flsNum)=fls;
        filesPt=filesPt+flsNum;
    end
end

close all;
warning off Images:initSize:adjustingMag; % Turn off image scaling warnings.
iptsetpref('ImshowBorder','tight'); % Make imshow display no border and thus print will save no white border.

for i=1:length(files)
	procImg(files{i});
end

fprintf(1,'preprocing Soma is finished. Thanks for your work!\n');
end

function procImg(filename)

global ori grayOri;
close all;

[pathstr, name]=fileparts(filename);
% Filename Without extension.
filenameWoExt=fullfile(pathstr,name);
annoMatFile=[filenameWoExt '.anno.mat'];
mc=[];
if exist(annoMatFile,'file')
    load(annoMatFile,'mc');
end

figure('Name',filename);
dataOri=imread(filename);
if ~isempty(mc)
    luCorner=mc.luCorner;
    rlCorner=mc.rlCorner;
    dataOri=dataOri(luCorner(1):rlCorner(1),luCorner(2):rlCorner(2),:);
end
imshow(dataOri);

fprintf(1,'Preproc soma file of %s.\n',filename);

files=getImgFileNames;
if isempty(files)
    return;
end
while length(files)>1
    fprintf(1,'Multiple soma files are input. Please choose only 1 file.\n');
    files=getImgFileNames;
    if files{1}==0
        return;
    end
end
somafile=files{1};

ori=imread(somafile);
if ~isempty(mc)
    ori=ori(luCorner(1):rlCorner(1),luCorner(2):rlCorner(2),:);
end
grayOri=getGrayImg(ori);

if ~isempty(mc)
    somaThre=mc.somaThre;
else
    somaThre=graythresh(grayOri)*255;
end
bw=applyThre(somaThre);
fprintf(1,'======================================================================\nThe present threshold is %d.\n',somaThre);
reply=input('If you want to reset the threshold, input here in range [0 254].\nOtherwise if the threshhold is ok, press ENTER\nAn integer or Enter: ','s');
while ~isempty(reply)
    somaThre=uint8(str2double(reply));
    bw=applyThre(somaThre);
    fprintf(1,'======================================================================\nThe present threshold is %d.\n',somaThre);
    reply=input('If you want to reset the threshold, input here in range [0 254].\nIf the threshhold is ok, press ENTER\nAn integer or Enter: ','s');
end

bw=adjustMask(bw);

infoline=sprintf('Save the soma preproc result?');
choice=questdlg(infoline,'Save Dialog','Save','Cancel','Save');
if strcmp(choice,'Cancel')
    fprintf(1,'User canceled.');
    return;
end

somaBwFile=[filenameWoExt '.somabw.png'];
imwrite(bw,somaBwFile,'png');


end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5


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
else
    whatStr='foreground';
    doStr='Delete';
end
infoline=sprintf('You have chosen mostly %s pixels. Do %s?',whatStr,doStr);
choice=questdlg(infoline,'Addition/Deletion','Add','Delete','AddWoAI',doStr);
% if strcmp(choice,'Cancel')
%     bw=[];
%     return;
aiFlag=0;
if strcmp(choice,'AddWoAI')
    bw=bw|mask;
    aiFlag=1;
elseif strcmp(choice,'Add')
    addFlag=1;
else
    addFlag=0;
end

if ~aiFlag
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
