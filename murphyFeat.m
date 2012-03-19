function murphyFeat

fprintf(1,'murphyFeat runs...\n');

addpath('boland_murphy_bioinfo_2001/matlab');

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

len=length(files);
for i=1:len
    fprintf(1,'Proc image: %s.\n',files{i});
	[bwFVec somaFVec branchFVec fnames]=procImg(files{i});
    if i==1
%         varNum=length(bwFVec);
        varNum=8;
        bwFMat=zeros(len,varNum);
        somaFMat=zeros(len,varNum);
        branchFMat=zeros(len,varNum);
        obfile=cell(len,1);
    end
    bwFMat(i,:)=bwFVec;
    somaFMat(i,:)=somaFVec;
    branchFMat(i,:)=branchFVec;
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
    murphDfmName=fullfile(pathname,[dirname{i} '.murph.dfm']);
    save(murphDfmName,'bwFMat','somaFMat','branchFMat','obfile','fnames');
    copyfile(murphDfmName,[pathname filesep '..']); % copy the filename to parent directory.
end

close all;
if length(files)>1
    helpdlg('branMorphProc finished.','Finish');
end

end

function [bwFVec somaFVec branchFVec fnames]=procImg(filename)

[pathname filename]=fileparts(filename);
cropFile=fullfile(pathname,[filename '.cut.png']);
bwFile=fullfile(pathname,[filename '.bw.png']);
somabwFile=fullfile(pathname,[filename '.somabw.png']);

ori=imread(cropFile);
bw=imread(bwFile);
bw=(bw~=0);
somabw=imread(somabwFile);
somabw=(somabw~=0);
grayOri=getGrayImg(ori);

% mask = mb_cropthresh(cropFile, []);

% Full
imageProc=grayOri.*uint8(bw); % Only cell pixels are kept.
[names, values] = mb_imgfeatures(imageProc, []);
hull = mb_imgconvhull(bw);
[names1, values1] = mb_hullfeatures(imageproc, hull);
names=[names names1];
values=[values values1];
[names1, values1] = mb_imgedgefeatures(imageproc);
names=[names names1];
values=[values values1];
[znames, zvalues] = mb_zernike(imageproc,12,)
sprintf(names{1});
bwFVec=values;

% Soma
imageProc=grayOri.*uint8(somabw);
[names, values] = mb_imgfeatures(imageProc, []);
sprintf(names{1});
somaFVec=values;

% Non-soma
nonsoma=bw-(bw&somabw);
nonsoma=nonsoma~=0;
imageProc=grayOri.*uint8(nonsoma);
[names, values] = mb_imgfeatures(imageProc, []);
sprintf(names{1});
branchFVec=values;

fnames=names;


end