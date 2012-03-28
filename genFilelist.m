function genFilelist
% genFilelist.
% Generate file lists for branMorphProc. The widthFlag information is also
% specified in the file. The output file name is 'datestr(now).fl'.

files=getImgFileNames;
if isempty(files)
	return;
end

pathname=fileparts(files{1});
fid=fopen(fullfile(pathname,'data.fl'),'w');
for i=1:length(files)
    % Now only filename without pathname is saved, so filelist could be
    % used across platforms.
    [pathname filename extname]=fileparts(files{i});
    sprintf(pathname);
    fprintf(fid,'%s\n',[filename extname]);
end

end

