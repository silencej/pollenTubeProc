function A=alignRtMatrix

% startNum=200; % The new branch num starts from startNum. Set this number so no tree has branches more than the number.;

files=getFilesInDir('*.rt.mat');

if isempty(files)
    return;
end

%% Obtain the reference tree.
refMat=inf(300,2); % [parentId, id].

% Use the first file to initialize the refMat.
rtMatrix=[];
load(files{1},'rtMatrix');
if isempty(rtMatrix)
    error('Error: The rtMatrix of %s is empty.\n',files{1});
end
contentPt=size(rtMatrix,1); % Content pointer in refMat, eg. the line num of non-inf lines.
refMat(1:contentPt,:)=rtMatrix(:,1:2);
labelMax=max(refMat(:));

% Absorb all other trees.
for i=2:length(files)
   load(files{i},'rtMatrix');
   if isempty(rtMatrix)
       error('Error: The rtMatrix of %s is empty.\n',files{i});
   end
   
end



end