function files=getFilelist(fls)

if nargin==0
    fls=getImgFileNames({'*.fl','Filelist file'});
    
    if isempty(fls)
        return;
    end
else
    fls={fls};
end

filesPt=0;
files=cell(1,1);
dirname=fileparts(fls{1});
for i=1:length(fls)
    fid=fopen(fls{i},'r');
    tline=fgetl(fid);
    while ischar(tline)
        filesPt=filesPt+1;
        [pn fn]=fileparts(tline);
        sprintf(pn);
        files(filesPt)={fullfile(dirname,fn)};
        tline=fgetl(fid);
    end
    % If there is no char line in filelist.
    if ~filesPt
        files=cell(0,1);
    end
    fclose(fid);
end

end