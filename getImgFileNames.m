function [filenames flFlag]=getImgFileNames(filterSpec)
% filenames will always be a cell array.
% filterSpec should be like {'*.png;*.PNG','Images';'*.*','All'}.
% flFlag: filelist flag.

if nargin==0
	filterSpec={'*.png;*.PNG;*.jpg;*.jpeg;*.JPG;*.JPEG;*.tif;*.tiff;*.TIF;*.TIFF','Images';'*.fl','filelist';'*.*','All'};
end

% Open path history.
oldDir='./';
if exist('path.hist','file')
	fid=fopen('path.hist','rt');
	oldDir=fgetl(fid);
	fclose(fid);
%	 oldDir=strrep(oldDir,' ','\ '); % escape the space in path name.
%	 oldDir={oldDir}; % Make it a cell so space in filename will be safe.
end
if ~ischar(oldDir)
	oldDir='./';
end

[filename,pathname,fIdx] = uigetfile(filterSpec,'Select Images',oldDir,'multiselect','on');

if isequal(filename,0)
% 	disp('User Pressed Cancel.');
% 	filenames={0};
    filenames='';
    flFlag=0;
	return;
end

% If input a filelist, then read the filelist file and return all filenames
% in it.
flFlag=0;
if fIdx==2
    flFlag=1;
    if iscell(filename)
        error('getImgFileNames: only one filelist could be input each time.');
    end
    filenames=getFilelist(fullfile(pathname,filename));
%     return;
%     tempFiles=files;
%     filesPt=0;
%     files=cell(1,1);
%     for i=1:length(tempFiles)
%         fls=getFilelist(tempFiles{i}); % files.
%         flsNum=length(fls);
%         files(filesPt+1:filesPt+flsNum)=fls;
%         filesPt=filesPt+flsNum;
%     end
elseif ~iscell(filename)
	filenames=fullfile(pathname,filename);
	filenames={filenames};
else
	l=length(filename);
	filenames=cell(l,1);
	for i=1:l
		filenames(i)={[pathname filename{i}]};
	end
end

% Write path history.
if ~strcmpi(oldDir,pathname)
	fid=fopen('path.hist','wt');
	fprintf(fid,'%s',pathname);
	fclose(fid);
end

end