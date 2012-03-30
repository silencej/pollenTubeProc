function printFeat
% Similar to makeDfm.

fprintf(1,'Output directory feature matrix now...\n');

files=getImgFileNames({'*.dfm','DFM files'});

if isempty(files)
	return;
end

% 'psArea', 'bbLen', 'bbChildNum', 'flBrNum', 'sbPos', ...
%    'sbLen','bbWidth', 'bbTipWidth', 'sbWidth', 'sbTipWidth', ...
%    'bubbleNum', 'lbRad','widthRatio','bbIntStd','avgIntRatio','wavyCoef','wavyNum'

dfm=[];
obfile={};
% fnames='';
for i=1:length(files)
	load(files{i},'dfm','obfile','-mat');
	fprintf(1,'==================\nDFM file %s.\n',files{i});
	for j=1:size(dfm,1)
		fprintf(1,'Image %s:\n',obfile{j});
		fprintf(1,'psArea=%g,',dfm(j,1));
		fprintf(1,'bbLen=%g,',dfm(j,2));
		fprintf(1,'bbChildNum=%g,',dfm(j,3));
		fprintf(1,'flBrNum=%g,',dfm(j,4));
		fprintf(1,'sbPos=%g,',dfm(j,5));
		fprintf(1,'sbLen=%g,',dfm(j,6));
		fprintf(1,'bbWidth=%g,',dfm(j,7));
		fprintf(1,'bbTipWidth=%g,',dfm(j,8));
		fprintf(1,'sbWidth=%g,',dfm(j,9));
		fprintf(1,'sbTipWidth=%g,',dfm(j,10));
		fprintf(1,'bubbleNum=%g,',dfm(j,11));
		fprintf(1,'lbRad=%g,',dfm(j,12));
		fprintf(1,'widthRatio=%g,',dfm(j,13));
		fprintf(1,'bbIntStd=%g,',dfm(j,14));
		fprintf(1,'avgIntRatio=%g,',dfm(j,15));
		fprintf(1,'wavyCoef=%g,',dfm(j,16));
		fprintf(1,'wavyNum=%g.\n',dfm(j,17));
	end
end



end