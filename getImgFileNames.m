function filenames=getImgFileNames(filterSpec)
% filenames will always be a cell array.
% filterSpec should be like {'*.png;*.PNG','Images';'*.*','All'}.

if nargin==0
	filterSpec={'*.png;*.PNG;*.jpg;*.jpeg;*.JPG;*.JPEG;*.tif;*.tiff;*.TIF;*.TIFF','Images';'*.*','All'};
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

[filename,pathname] = uigetfile(filterSpec,'Select Images',oldDir,'multiselect','on');

if isequal(filename,0)
% 	disp('User Pressed Cancel.');
% 	filenames={0};
    filenames='';
	return;
end

if ~strcmpi(oldDir,pathname)
	fid=fopen('path.hist','wt');
	fprintf(fid,'%s',pathname);
	fclose(fid);
end

if ~iscell(filename)
	filenames=fullfile(pathname,filename);
	filenames={filenames};
else
	l=length(filename);
	filenames=cell(l,1);
	for i=1:l
		filenames(i)={[pathname filename{i}]};
	end
end

end