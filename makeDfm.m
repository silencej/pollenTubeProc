function makeDfm(dirname,dfmname)
% Make directory feature matrix.
% makeDfm('./','a'), will make ./a.dfm

if nargin==0
    dirname='';
end
if nargin==0
    dfmname='';
end

fprintf(1,'Make directory feature matrix now...\n');

files=getFilesInDir('*.fv.mat',dirname);

if isempty(files)
    fprintf(1,'There is no fv.mat files.\n');
	return;
end

% drm=struct([]); % Empty struct with no field.
dataNum=length(files);
obfile=cell(dataNum,1); % Observation filename str-cell.

load(files{1},'fVec','fnames');
varNum=length(fVec);
dfm=zeros(dataNum,varNum);
dfm(1,:)=fVec;
obfile(1)=files(1);
% If dataNum==1, it will be ok.
for i=2:dataNum
    load(files{i});
    dfm(i,:)=fVec;
    obfile(i)=files(i);
end

if isempty(dfmname)
    [pathname filename]=fileparts(files{i});
    sprintf(filename);
    [file pathname]=uiputfile(fullfile(pathname,'res.dfm'),'Save the dfm');
    % If user press cancel, file is 0.
    if ~file
        return;
    end
    dfmname=fullfile(pathname,file);
    save(dfmname,'dfm','obfile','fnames');
else
    save([dfmname '.dfm'],'dfm','obfile','fnames');
end

fprintf(1,'DFM of %s is generated.\n',dirname);

end