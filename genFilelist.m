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
    fprintf(fid,'%s\n',files{i});
end

end

