function makeDfm
% Make directory feature matrix.

fprintf(1,'Make directory feature matrix now...\n');

files=getFilesInDir('*.fv.mat');

if isempty(files)
    fprintf(1,'There is no fv.mat files.\n');
	return;
end

% drm=struct([]); % Empty struct with no field.
dataNum=length(files);
dfm=zeros(dataNum,12);

for i=1:dataNum
    load(files{i});
    dfm(i,:)=fVec;
end

[pathname filename]=fileparts(files{i});
sprintf(filename);
[file pathname]=uiputfile(fullfile(pathname,'res.dfm'),'Save the dfm');
% If user press cancel, file is 0.
if ~file
    return;
end
save(fullfile(pathname,file),'dfm');


end