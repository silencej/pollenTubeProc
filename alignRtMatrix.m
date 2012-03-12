function alignRtMatrix

% startNum=200; % The new branch num starts from startNum. Set this number so no tree has branches more than the number.;

debugFlag=1;

% Padding all rtMatrix into a 3th-order tree, e.g., each node has 3
% children, except for the root, which has 6 children.
fstChildNum=6;
childNum=3;
% levels: 0~levelNum-1.
levelNum=3;
% bblNum=3;
% artMatColNum=4+bblNum*2; % Aligned root tree mat col num. [brPos len width tipWidth bubbles...].
% 6+6*3+6*3*3+...
% Not: 1+6+6*3+6*3*3+... since the root is soma/pollen.
artMatRowNum=fstChildNum*(childNum^(levelNum-1)-1)/(childNum-1);

%% Start.

fprintf(1,'Align DRMs now...\n');

% files=getFilesInDir('*.rt.mat');
% 
% if isempty(files)
%     fprintf(1,'There is no rt.mat files.\n');
% 	return;
% end

files=getImgFileNames('*.drm');
if isempty(files)
%     refMat=zeros(0,2);
    return;
end


%% Align.

% Obtain the reference tree.
% refMat=inf(300,2); % [parentId, id].
% rtMatrix=inf(2); % Fake an initialization to suppress the annoying warning.

% Put all rtMat to rtMats.
drm=cell(0,2);
gNum=length(files); % group number.
rtMats=cell(0,2); % {rtMat, groupId}.
rtMatsPt=0;
for i=1:gNum
    load(files{i},'drm','-mat');
%     drm=a.drm;
    rtMatNum=size(drm,1);
    rtMats(rtMatsPt+1:rtMatsPt+rtMatNum,1)={drm{:,2}};
    rtMats(rtMatsPt+1:rtMatsPt+rtMatNum,2)=num2cell(repmat(i,1,rtMatNum));
    rtMatsPt=rtMatsPt+rtMatNum;
end

% Get the colNum.
colNum=0; % Used to record the actual col number.
for i=1:size(rtMats,1)
    if colNum<size(rtMats{i,1},2)
        colNum=size(rtMats{i,1},2);
    end
end

artMats=cell(0,2);
% Padding the rtMatricies.
for i=1:size(rtMats,1)
    % Initials.
    artMat=zeros(artMatRowNum,colNum);
%     treeIdx=0; % The present parent node's tree index.
    artConPt=0;
    
    rtMat=rtMats{i,1};

    if debugFlag
        printMat(rtMat);
    end
    
    % TODO: what if matPart is empty, e.g. the pid has no child?
    
    pidPt=0; % pid visit pt.
    pidConPt=1; % pid content pt.
    pidVec=zeros(30,1); % parent id vector.
    while pidPt<pidConPt
        pidPt=pidPt+1;
        pid=pidVec(pidPt);
        matPart=rtMat(rtMat(:,1)==pid,:);
        matPartLen=size(matPart,1);
        if (pid==0 && matPartLen>fstChildNum) || (pid>0 && matPartLen>childNum)
            error('In rtMat %g: The pid %g has %g children, which exceeds limit.',i,pid,matPartLen);
        end
        if ~pid
            % Root.
            contentPart=zeros(fstChildNum,colNum);
            contentPart(1:matPartLen,1:size(matPart,2)-2)=matPart(:,3:end); % Erase the pid and id cols from rtMat.
            artMat(1:fstChildNum,:)=contentPart;
            artConPt=artConPt+fstChildNum;
        else
            contentPart=zeros(childNum,colNum);
            contentPart(1:matPartLen,1:size(matPart,2)-2)=matPart(:,3:end);
            if artConPt+childNum>artMatRowNum
                error('In %g rtMat: artConPt+childNum>artMatRowNum.');
            end
            artMat(artConPt+1:artConPt+childNum,:)=contentPart;
            artConPt=artConPt+childNum;
        end
        pidVec(pidPt+1:pidPt+matPartLen)=matPart(:,2);
        pidConPt=pidConPt+matPartLen;
    end
    artMats{i,1}=artMat;
    artMats{i,2}=rtMats{i,2};
end

%% Do PCA and plot the points in the largest two dimensions.

% Transform the artMats.
obNum=size(artMats,1); % observation number.
varNum=floor(artMatRowNum*colNum); % variable number.
mat=zeros(obNum,varNum);
gVec=zeros(obNum,1);
for i=1:obNum
    tmp=artMats{i,1};
    mat(i,:)=reshape(tmp',1,varNum);
    gVec(i)=artMats{i,2};
end

[coef score]=princomp(mat);
gNum=max(gVec);
figure;
% Plot first dataset.
plot(score(gVec==1,1),score(gVec==1,2),'xr');

if gNum>=2
    hold on;
    plot(score(gVec==2,1),score(gVec==2,2),'xg');
end

if gNum>=3
    plot(score(gVec==3,1),score(gVec==3,2),'xb');
end

hold off;

end

%% 
function printMat(rtMat)

% fprintf(1,'The rtMatrix of %s is:\n',files{1});
fprintf(1,'===============================\n');
colNum=size(rtMat,2);
fprintf(1,[repmat('%g\t',1,colNum-1) '%g\n'],rtMat');

end

%%

% function noUse
% 
% % Use the first file to initialize the refMat.
% 
% load(files{1},'rtMatrix');
% if isempty(rtMatrix)
% 	error('Error: The rtMatrix of %s is empty.\n',files{1});
% end
% contentPt=size(rtMatrix,1); % Content pointer in refMat, eg. the line num of non-inf lines.
% refMat(1:contentPt,:)=rtMatrix(:,1:2);
% if debugFlag
% 	fprintf(1,'The rtMatrix of %s is:\n',files{1});
% 	colNum=size(rtMatrix,2);
% 	fprintf(1,[repmat('%g\t',1,colNum-1) '%g\n'],rtMatrix');
% end
% labelMax=max(rtMatrix(:,2));
% 
% % Absorb all other trees.
% for i=2:length(files)
% 	load(files{i},'rtMatrix');
% 	if isempty(rtMatrix)
% 		error('Error: The rtMatrix of %s is empty.\n',files{i});
% 	end
% 
% 	if debugFlag
% 		fprintf(1,'The rtMatrix of %s is:\n',files{i});
% 		colNum=size(rtMatrix,2);
% 		fprintf(1,[repmat('%g\t',1,colNum-1) '%g\n'],rtMatrix');
% 	end
% 
% 	parentIds=unique(rtMatrix(:,1)); % parentIds is in ascending order.
% 	% In rtMatrix, parents should always be on top of children.
% 	% The visit should always be done on parents first before children, so the parentIds should not be used for indexing in FOR loop.
% 	for j=1:size(rtMatrix,1)
% 		pid=rtMatrix(j,1); % Parent id.
% 		% If the parentId is visited, then continue.
% 		if ~find(parentIds==pid,1)
% 			continue;
% 		end
% 		refPart=refMat(refMat(:,1)==pid,:);
% 		matPart=rtMatrix(rtMatrix(:,1)==pid,1:2);
% 		parentIds(parentIds==pid)=inf; % Mark the pid as visited.
% 		for k=1:size(matPart,1)
% 			if size(refPart,1)<k
% 				labelMax=labelMax+1;
% 				contentPt=contentPt+1;
% 				refMat(contentPt,:)=[pid labelMax];
%                 rtMatrix(rtMatrix(:,2)==matPart(k,2),2)=labelMax;
% 				rtMatrix(rtMatrix(:,1)==matPart(k,2),1)=labelMax;
% 				parentIds(parentIds==matPart(k,2))=labelMax; % Since the parents are visited earlier, the change will always happen before the parentId is used.
% 				continue;
% 			end
% 			% If the refPart and matPart have different children label at the same position.
% 			if refPart(k,2)~=matPart(k,2)
% 				labelMax=labelMax+1;
% 				refMat(refMat(:,2)==refPart(k,2),2)=labelMax;
% 				refMat(refMat(:,1)==refPart(k,2),1)=labelMax;
% 				rtMatrix(rtMatrix(:,2)==matPart(k,2),2)=labelMax;
% 				rtMatrix(rtMatrix(:,1)==matPart(k,2),1)=labelMax;
% 				parentIds(parentIds==matPart(k,2))=labelMax; % Since the parents are visited earlier, the change will always happen before the parentId is used.
% 			end
% 		end
% 	end
% end
% 
% refMat=refMat(refMat(:,1)~=inf,:);
% 
% if debugFlag
% 	fprintf(1,'The ref Matrix is:\n');
% 	colNum=size(refMat,2);
% 	fprintf(1,[repmat('%g\t',1,colNum-1) '%g\n'],refMat');
% end
% 
% % Generate the big dirRtMat file.
% 
% 
% %%
% 
% 
% parId=-1; % Currently visited parent id.
% parIdMax=0; % The present maximum parent id.
% % Breadth-first traversal of the tree.
% while parId<parIdMax
%     childNum=0;
%     parId=parId+1;
%     % Find the max child number for current parentId.
%     for i=1:size(rtMats,1)
%         rtMat=rtMats{i,1}; % One rtMat. no 's!
%         % Update the max parent id.
%         tempPar=max(rtMat(:,1));
%         if tempPar>parIdMax
%             parIdMax=tempPar;
%         end
%         len=length(find(rtMat(:,1)==parId));
%         if childNum<len
%             childNum=len;
%         end
%     end
%     for i=1:size(rtMats,1)
%         
%     end
% end
% 
% end
