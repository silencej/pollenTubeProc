function makeDrm
% Make directory root tree matrix.

% debugFlag=1;

fprintf(1,'Make directory rtMatrix now...\n');

files=getFilesInDir('*.rt.mat');

if isempty(files)
    fprintf(1,'There is no rt.mat files.\n');
	return;
end

% drm=struct([]); % Empty struct with no field.
drm=cell(length(files),2); % {filename rtMat}.

for i=1:length(files)
    load(files{i});
    drm{i,1}=files{i};
    drm{i,2}=rtMatrix;
end

[pathname filename]=fileparts(files{i});
sprintf(filename);
[file pathname]=uiputfile(fullfile(pathname,'res.drm'),'Save the drm');
% If user press cancel, file is 0.
if ~file
    return;
end
save(fullfile(pathname,file),'drm');

end