function murphyFeat

fprintf(1,'murphyFeat runs...\n');

scale=0.2131; % um/pixel.
% Tobaco
radius=15;
% Tomato
% radius=;

% addpath('boland_murphy_bioinfo_2001/matlab');
addpath('slicFeat/matlab');
% addpath(genpath('SLIC'));

files=getImgFileNames;
if isempty(files)
	return;
end

len=length(files);
for i=1:len
    fprintf(1,'Proc image: %s.\n',files{i});
% 	[bwFVec somaFVec branchFVec fnames]=procImg(files{i});
    [fVec fnames]=procImg(files{i},scale,radius);
    if i==1
        varNum=length(fVec);
%         varNum=8;
        dfm=zeros(len,varNum);
%         somaFMat=zeros(len,varNum);
%         branchFMat=zeros(len,varNum);
        obfile=cell(len,1);
    end
%     bwFMat(i,:)=bwFVec;
%     somaFMat(i,:)=somaFVec;
%     branchFMat(i,:)=branchFVec;
    dfm(i,:)=fVec;
    [pathname filename]=fileparts(files{i});
    sprintf(pathname);
    obfile(i)={filename};
end
sprintf(fnames{1});

% If use filelist, then makeDfm directly for you.
if flFlag
    pathname=fileparts(files{1});
    regCond=['(?<=' filesep ')[^' filesep ']*$'];
    dirname=regexp(pathname,regCond,'match'); % dirname is a cell string.
%     makeDfm(pathname,fullfile(pathname,dirname{1}));
    murphDfmName=fullfile(pathname,[dirname{1} '.murph.dfm']);
%   save(murphDfmName,'bwFMat','somaFMat','branchFMat','obfile','fnames');
    save(murphDfmName,'dfm','obfile','fnames');
    copyfile(murphDfmName,[pathname filesep '..']); % copy the filename to parent directory.
end

close all;
if length(files)>1
    helpdlg('branMorphProc finished.','Finish');
end

end


function [fVec fnames]=procImg(filename,scale,radius)
% function [bwFVec somaFVec branchFVec fnames]=procImg(filename)

[pathname filename]=fileparts(filename);
cropFile=fullfile(pathname,[filename '.cut.png']);
bwFile=fullfile(pathname,[filename '.bw.png']);
% somabwFile=fullfile(pathname,[filename '.somabw.png']);

ori=imread(cropFile);
bw=imread(bwFile);
bw=(bw~=0);
% somabw=imread(somabwFile);
% somabw=(somabw~=0);
grayOri=getGrayImg(ori);

% mask = mb_cropthresh(cropFile, []);

% Full
imageProc=grayOri.*uint8(bw); % Only cell pixels are kept.
% har
har_pixsize=1.15; % um/pixel.
har_intbins=256;
% scale=0.2131; % um/pixel.
% radius=15;

nonobjimg=grayOri.*uint8(~bw);
% img - image features (8 or 14 features).
% hul - hull features (3 features)
% edg - edge features (5 features)
% mor - morphological set (includes img, hul, edg, in this order).
% zer - zernike features (49 features)
% har - haralick texture features (13 features)
% wav - wavelet features (30 features)
% skl - skeleton features (5 features)
% nof - non-object fluorescence feature(s) (currently 1 feature)
featsets={'img','hul','edg','mor','zer','har','wav','skl','nof'};
[feat_names, feat_vals, feat_slf] = ...
    ml_features(imageProc, [], bw, featsets, scale, radius, ...
		nonobjimg, har_pixsize, har_intbins);

    
    
% [names, values] = mb_imgfeatures(imageProc, []);
% hull = mb_imgconvhull(bw);
% [names1, values1] = mb_hullfeatures(imageproc, hull);
% names=[names names1];
% values=[values values1];
% [names1, values1] = mb_imgedgefeatures(imageproc);
% names=[names names1];
% values=[values values1];
% [znames, zvalues] = mb_zernike(imageproc,12);
% sprintf(names{1});
% bwFVec=values;
% 
% % Soma
% imageProc=grayOri.*uint8(somabw);
% [names, values] = mb_imgfeatures(imageProc, []);
% sprintf(names{1});
% somaFVec=values;
% 
% % Non-soma
% nonsoma=bw-(bw&somabw);
% nonsoma=nonsoma~=0;
% imageProc=grayOri.*uint8(nonsoma);
% [names, values] = mb_imgfeatures(imageProc, []);
% sprintf(names{1});
% branchFVec=values;

sprintf(feat_slf{1});
fnames=feat_names;
fVec=feat_vals;

end