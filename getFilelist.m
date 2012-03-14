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
for i=1:length(fls)
    fid=fopen(fls{i},'r');
    %     if fid==-1
    %         continue;
    %     end
    tline=fgetl(fid);
    while ischar(tline)
        filesPt=filesPt+1;
        files(filesPt)={tline};
        tline=fgetl(fid);
    end
    fclose(fid);
end

end