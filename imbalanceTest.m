function imbalanceTest


addpath(genpath('randFor/RF_Class_C'));

fprintf(1,'Imba test on simulated now...\n');
close all;

dfm=0;
wildtypeFile='simuPollens/allWildtype.dfm';
load(wildtypeFile,'dfm','obfile','fnames','-mat');

gVec=inf(50,1); % group id vector.

% gnames=cell(2,1); % group names.
gnames=cell(6,1); % group names.

varNum=size(dfm,2);
dfms=inf(50,varNum);
dfmNum=size(dfm,1);
dfms(1:dfmNum,:)=dfm;
gVec(1:dfmNum)=1;

% wtDfm=dfm;

% [pathname filename extname]=fileparts(wildtypeFile);
% sprintf([pathname extname]);
gnames(1)={'Wildtype'};
dfmsPt=dfmNum;

files=getImgFileNames('*.dfm');
if isempty(files)
    return;
end

for k=1:length(files)
    load(files{k},'dfm','obfile','-mat');
    dfm=dfm(1:3,:);
%     obfile=obfile(1:3,:);
    
%     dfms=[wtDfm; dfm];
%     gVec=ones(size(wtDfm,1)+size(dfm,1),1);
%     gVec(size(wtDfm,1)+1:end)=2;
    
    dfmNum=size(dfm,1);
    dfms(dfmsPt+1:dfmsPt+dfmNum,:)=dfm;
    gVec(dfmsPt+1:dfmsPt+dfmNum)=k+1;
%     obs(dfmsPt+1:dfmsPt+dfmNum)=obfile;
    dfmsPt=dfmsPt+dfmNum;

    [pathname filename extname]=fileparts(files{k});
    sprintf([pathname extname]);
%     gnames(2)={filename};
    gnames(k+1)={filename};
    
end

gVec=gVec(gVec~=inf);
dfms=dfms(1:length(gVec),:);


%%

dfms=zscore(dfms);
X = dfms;
Y = gVec;

[N D] =size(X);
sprintf(num2str(D(1)));

% Permute.
% randvector = randperm(N);
% %randomly split into 2/3 examples for training and rest for testing
% trainLen=ceil(N*2/3);
% X_trn = X(randvector(1:trainLen),:);
% Y_trn = Y(randvector(1:trainLen));
% X_tst = X(randvector(trainLen+1:end),:);
% Y_tst = Y(randvector(trainLen+1:end));

% % Leave-one-out random forest.
% Extra options.
exopt.replace=1;
% exopt.classwt=;
exopt.sampsize=N-1; % Leave-one-out.
exopt.importance=1;
exopt.do_trace=0;
% model = classRF_train(X_trn,Y_trn,10000,0,exopt);
% model = classRF_train(X,Y,10000,0,exopt);

% maxMtry=50;
% For murphy, set it to 133.
maxMtry=D+1; % Set to the number of features + 1.
errVec=zeros(maxMtry,1);
for i=1:maxMtry
    model = classRF_train(X,Y,10000,i,exopt);
    err=model.errtr;
    errorRate=mean(err(:,1));
    errVec(i)=errorRate;
    fprintf(1,'In train phase, average error rate: %g. mtry=%g.\n',errorRate,i);
end
[minVal idx]=min(errVec);
fprintf(1,'The smallest error rate is %g, mtry=%g.\n',minVal,idx);

model = classRF_train(X,Y,100000,idx,exopt);

gini=model.importance;
gini=gini(:,end);
[ginis inds]=sort(gini,'descend');
fnamesS=fnames;
for i=1:length(fnamesS)
    fnamesS(i)=fnames(inds(i));
end
sprintf(num2str(ginis(1)));
err=model.errtr;
merr=mean(err,1);
errorRate=merr(1);
classErr=merr(2:end);
fprintf(1,'In train phase, average error rate: %g\n',errorRate);
fprintf(1,'Error rates for classes: \n');
for i=1:length(gnames)
    fprintf(1,'%s\t',strtok(gnames{i},'- '));
end
fprintf(1,'\n');
fprintf(1,'%g\t',classErr);
fprintf(1,'\n');
fprintf(1,'Sorted variables: ');
fprintf(1,'%s\t%s\t%s\t%s.\n',fnamesS{1},fnamesS{2},fnamesS{3},fnamesS{4});
fprintf(1,'Gini index: %g\t%g\t%g\t%g.\n',ginis(1),ginis(2),ginis(3),ginis(4));

% Leave-one-out cross validation.
% fVotes=zeros(length(fnames),1); % The first 3 votes.
errorRate=0;
tstVec=zeros(N,1);
hatVec=zeros(N,1);
for i=1:N
    X_trn = X;
    Y_trn = Y;
    X_trn(i,:)=[];
    Y_trn(i)=[];
    X_tst = X(i,:);
    Y_tst = Y(i);
    model = classRF_train(X_trn,Y_trn,10000);
%     [s idx]=sort(model.importance,'descend');
%     sprintf(num2str(s(1)));
%     fVotes(idx(1))=fVotes(idx(1))+1;
%     fVotes(idx(2))=fVotes(idx(2))+1;
%     fVotes(idx(3))=fVotes(idx(3))+1;
Y_hat = classRF_predict(X_tst,model);
tstVec(i)=Y_tst;
hatVec(i)=Y_hat;
% C=confusionmat(Y_tst,Y_hat);
% aveConf=aveConf+C;

er=length(find(Y_hat~=Y_tst))/length(Y_tst);
errorRate=errorRate+er;
end
errorRate=errorRate/N;
% errorRate=er/N;
 
% % example 1:  simply use with the defaults
% extra_options.replace = 0 ;
% model = classRF_train(X_trn,Y_trn, 500, 0, extra_options);
% [s idx]=sort(model.importance,'descend');
% fprintf(1,'The most important features: %s - %g, %s - %g, %s - %g.\n',fnames{idx(1)}, s(1), fnames{idx(2)}, s(2),fnames{idx(3)}, s(3));


%fprintf(1,'The total sample size is %g\n.',size(dfms,1));

% [s idx]=sort(fVotes,'descend');
% fprintf(1,'The most important features: %s - %g votes, %s - %g, %s - %g.\n',fnames{idx(1)}, s(1), fnames{idx(2)}, s(2),fnames{idx(3)}, s(3));

% model = classRF_train(X_trn,Y_trn);
% Y_hat = classRF_predict(X_tst,model);
% fprintf(1,'\nexample 1: error rate %f\n',   length(find(Y_hat~=Y_tst))/length(Y_tst));

fprintf(1,'Predict phase: average error rate: %g\n',errorRate);
[C order]=confusionmat(tstVec,hatVec);
C
classNum=length(order);
cdNum=zeros(classNum,1); % Class data number.
for i=1:classNum
    cdNum(i)=length(find(tstVec==order(i)));
end
C=C./repmat(cdNum,1,classNum);
figure;
% aveConf=aveConf./N;
imagesc(C);
% imagesc(aveConf);
colorbar;
set(gca,'XTick',1:classNum);
set(gca,'XTickLabel',strtok(gnames,'- '),'FontSize',8);
set(gca,'YTick',1:classNum);
set(gca,'YTickLabel',strtok(gnames,'- '),'FontSize',8);


% end

end