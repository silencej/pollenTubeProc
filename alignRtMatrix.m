function refMat=alignRtMatrix

% startNum=200; % The new branch num starts from startNum. Set this number so no tree has branches more than the number.;

debugFlag=1;

fprintf(1,'Align rtMatrix now...\n');

files=getFilesInDir('*.rt.mat');

if isempty(files)
    fprintf(1,'There is no rt.mat files.\n');
	return;
end

%% Obtain the reference tree.
refMat=inf(300,2); % [parentId, id].
rtMatrix=inf(2); % Fake an initialization to suppress the annoying warning.

% Use the first file to initialize the refMat.
% rtMatrix=[];

load(files{1},'rtMatrix');
if isempty(rtMatrix)
	error('Error: The rtMatrix of %s is empty.\n',files{1});
end
contentPt=size(rtMatrix,1); % Content pointer in refMat, eg. the line num of non-inf lines.
refMat(1:contentPt,:)=rtMatrix(:,1:2);
if debugFlag
	fprintf(1,'The rtMatrix of %s is:\n',files{1});
	colNum=size(rtMatrix,2);
	fprintf(1,[repmat('%g\t',1,colNum-1) '%g\n'],rtMatrix');
end
labelMax=max(rtMatrix(:,2));

% Absorb all other trees.
for i=2:length(files)
	load(files{i},'rtMatrix');
	if isempty(rtMatrix)
		error('Error: The rtMatrix of %s is empty.\n',files{i});
	end

	if debugFlag
		fprintf(1,'The rtMatrix of %s is:\n',files{i});
		colNum=size(rtMatrix,2);
		fprintf(1,[repmat('%g\t',1,colNum-1) '%g\n'],rtMatrix');
	end

	parentIds=unique(rtMatrix(:,1)); % parentIds is in ascending order.
	% In rtMatrix, parents should always be on top of children.
	% The visit should always be done on parents first before children, so the parentIds should not be used for indexing in FOR loop.
	for j=1:size(rtMatrix,1)
		pid=rtMatrix(j,1); % Parent id.
		% If the parentId is visited, then continue.
		if ~find(parentIds==pid,1)
			continue;
		end
		refPart=refMat(refMat(:,1)==pid,:);
		matPart=rtMatrix(rtMatrix(:,1)==pid,1:2);
		parentIds(parentIds==pid)=inf; % Mark the pid as visited.
		for k=1:size(matPart,1)
			if size(refPart,1)<k
				labelMax=labelMax+1;
				contentPt=contentPt+1;
				refMat(contentPt,:)=[pid labelMax];
                rtMatrix(rtMatrix(:,2)==matPart(k,2),2)=labelMax;
				rtMatrix(rtMatrix(:,1)==matPart(k,2),1)=labelMax;
				parentIds(parentIds==matPart(k,2))=labelMax; % Since the parents are visited earlier, the change will always happen before the parentId is used.
				continue;
			end
			% If the refPart and matPart have different children label at the same position.
			if refPart(k,2)~=matPart(k,2)
				labelMax=labelMax+1;
				refMat(refMat(:,2)==refPart(k,2),2)=labelMax;
				refMat(refMat(:,1)==refPart(k,2),1)=labelMax;
				rtMatrix(rtMatrix(:,2)==matPart(k,2),2)=labelMax;
				rtMatrix(rtMatrix(:,1)==matPart(k,2),1)=labelMax;
				parentIds(parentIds==matPart(k,2))=labelMax; % Since the parents are visited earlier, the change will always happen before the parentId is used.
			end
		end
	end
end

refMat=refMat(refMat(:,1)~=inf,:);

if debugFlag
	fprintf(1,'The ref Matrix is:\n');
	colNum=size(refMat,2);
	fprintf(1,[repmat('%g\t',1,colNum-1) '%g\n'],refMat');
end

end
