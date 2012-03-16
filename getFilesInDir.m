function files=getFilesInDir(filespec,dirname)
% files=getFilesInDir(filespec,dirname).
% Example: files=getFilesInDir(*.png), then files will be all the png
% filenames in the specified directory.
% If dirname is empty or omitted, then uigetdir will be called to choose a
% directory.

if nargin<2
    dirname='';
end

if isempty(dirname)
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
    dirname=uigetdir(oldDir);

    if isequal(dirname,0)
        % 	disp('User Pressed Cancel.');
        files='';
        return;
    end
    
end

dirname=[dirname filesep];
if ~strcmpi(oldDir,dirname)
	fid=fopen('path.hist','wt');
	fprintf(fid,'%s',dirname);
	fclose(fid);
end

files2=dir([dirname filespec]);
if isempty(files2)
	files='';
	return;
end

l=length(files2);
files=cell(l,1);
for i=1:l
	files(i)={[dirname files2(i).name]};
end

end