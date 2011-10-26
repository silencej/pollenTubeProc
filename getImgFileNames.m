function filenames=getImgFileNames
% filenames will always be a cell array.

% Open path history.
oldDir='./';
if exist('path.hist','file')
	fid=fopen('path.hist','rt');
	oldDir=fgetl(fid);
	fclose(fid);
end
if ~ischar(oldDir)
	oldDir='./';
end

[filename,pathname] = uigetfile({'*.png;*.PNG;*.jpg;*.jpeg;*.JPG;*.JPEG;*.tif;*.tiff;*.TIF;*.TIFF','Images';'*.*','All'},'Select Images',oldDir,'multiselect','on');

if isequal(filename,0)
	disp('User Pressed Cancel.');
    filenames={0};
	return;
end

fid=fopen('path.hist','wt');
fprintf(fid,'%s',pathname);
fclose(fid);

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