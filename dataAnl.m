function dataAnl


fprintf(1,'Data Analyze now...\n');
close all;

% files=getFilesInDir('*.rt.mat');
% 
% if isempty(files)
%     fprintf(1,'There is no rt.mat files.\n');
% 	return;
% end

files=getImgFileNames('*.dfm');
if isempty(files)
    return;
end

gVec=inf(50,1); % group id vector.
obs=cell(1,1); % observation file names.
gNum=length(files);
gnames=cell(gNum,1); % group names.
load(files{1},'dfm','obfile','fnames','-mat');
varNum=size(dfm,2);
dfms=inf(50,varNum);
dfmNum=size(dfm,1);
dfms(1:dfmNum,:)=dfm;
gVec(1:dfmNum)=1;
obs(1:dfmNum)=obfile;
[pathname filename extname]=fileparts(files{i});
sprintf([pathname extname]);
gnames(1)={filename};
dfmsPt=dfmNum;
for i=2:length(files)
    load(files{i},'dfm','obfile','-mat');
    dfmNum=size(dfm,1);
    dfms(dfmsPt+1:dfmsPt+dfmNum,:)=dfm;
    gVec(dfmsPt+1:dfmsPt+dfmNum)=i;
    obs(dfmsPt+1:dfmsPt+dfmNum)=obfile;
    dfmsPt=dfmsPt+dfmNum;
    [pathname filename extname]=fileparts(files{i});
    sprintf([pathname extname]);
    gnames(i,1)={filename};
end

gVec=gVec(gVec~=inf);
dfms=dfms(1:length(gVec),:);

% gNum=max(gVec);

%% Robust PCA.

% addpath('./libra/');


%% PCA.

[coef score]=princomp(zscore(dfms)); % Re-scale variables.
sprintf(num2str(coef(1)));

% figure;
% % h=scatter3(score(:,1),score(:,2),score(:,3),100,gVec,'filled');
% % h=scatter(score(:,1),score(:,2),100,gVec,'filled');
% title('PCA');
% % sc=get(h,'children');
% % ss=get(sc,'markersize');
% % cm=get(sc,'cdata');
% hold on;
% plot(score(gVec==1,1),score(gVec==1,2),'or','MarkerFaceColor','r');
% plot(score(gVec==2,1),score(gVec==2,2),'og','MarkerFaceColor','g');
% if gNum==2
%     legend(sc,gnames{1},gnames{2});
% elseif gNum==3
%     plot(score(gVec==3,1),score(gVec==3,2),'ob','MarkerFaceColor','b');
%     legend(gnames{1},gnames{2},gnames{3});
% elseif gNum==4
%     plot(score(gVec==3,1),score(gVec==3,2),'ob','MarkerFaceColor','b');
%     plot(score(gVec==4,1),score(gVec==4,2),'oc','MarkerFaceColor','c');
%     legend(gnames{1},gnames{2},gnames{3},gnames{4});
% end
% % varNum=size(dfms,2);
% % for i=1:varNum
% %     plot([0 coef(i,1)],[0 coef(i,2)],'-b');
% %     text(coef(i,1)+1,coef(i,2),fnames{i});
% % end
% axis tight;
% grid on;
% hold off;

figure;
title('biplot of PCA');
% 
% fnames={'psArea', 'bbLen', 'bbChildNum', 'flBrNum', 'sbPos', 'sbLen', 'bbWidth', 'bbTipWidth', 'sbWidth', 'sbTipWidth', 'bubbleNum', 'lbRad'};
% biplotWcf(coef(:,1:2),gVec,gnames,'scores',score(:,1:2),'varlabels',num2str((1:12)'),'obslabels',obs);
biplotWcf(coef(:,1:2),gVec,gnames,'scores',score(:,1:2),'varlabels',fnames,'obslabels',obs);

% obsNum=size(dfms,1);
% obsHandle=h(varNum*2+1:varNum*2+obsNum);
axis tight;

%% PCA without col 1, col 11 and col 12.

% dfms=dfms(:,[2 7 8]);
% [coef score]=princomp(zscore(dfms)); % Re-scale variables.
% sprintf(num2str(coef(1)));
% figure;
% title('biplot of PCA, without bubbles');
% % fnames={'bbLen', 'bbChildNum', 'flBrNum', 'sbPos', 'sbLen','bbWidth', 'bbTipWidth', 'sbWidth', 'sbTipWidth'};
% fnames={'bbLen','bbWidth', 'bbTipWidth'};
% % biplotWcf(coef(:,1:2),gVec,gnames,'scores',score(:,1:2),'varlabels',num2str((1:12)'),'obslabels',obs);
% biplotWcf(coef(:,1:2),gVec,gnames,'scores',score(:,1:2),'varlabels',fnames,'obslabels',obs);

%% 3d plot.

% % figure;
% % scatter3(dfms(:,1),dfms(:,2),dfms(:,3),50,gVec,'filled');

% figure;
% % h=scatter3(score(:,1),score(:,2),score(:,3),100,gVec,'filled');
% % h=scatter(score(:,1),score(:,2),100,gVec,'filled');
% title('Original');
% % sc=get(h,'children');
% % ss=get(sc,'markersize');
% % cm=get(sc,'cdata');
% hold on;
% score=zscore(dfms);
% plot3(score(gVec==1,1),score(gVec==1,2),score(gVec==1,3),'or','MarkerFaceColor','r');
% plot3(score(gVec==2,1),score(gVec==2,2),score(gVec==2,3),'og','MarkerFaceColor','g');
% if gNum==2
%     legend(gnames{1},gnames{2});
% end
% if gNum>=3
%     plot3(score(gVec==3,1),score(gVec==3,2),score(gVec==3,3),'ob','MarkerFaceColor','b');
%     legend(gnames{1},gnames{2},gnames{3});
% end
% if gNum>=4
%     plot3(score(gVec==4,1),score(gVec==4,2),score(gVec==4,3),'oc','MarkerFaceColor','c');
%     legend(gnames{1},gnames{2},gnames{3},gnames{4});
% end
% xlabel('bbLen');
% ylabel('bbWidth');
% zlabel('bbTipWidth');
% hold off;
% axis tight;
% view(3);
% grid on;

%% Barplot.

% figure;
% boxplot(zscore(dfms));

%%

% sprintf(num2str(lh));
% hMarkers=findobj(lh,'type','patch');
% set(hMarkers, 'MarkerEdgeColor','k', 'MarkerFaceColor','k');
% lc=findall(lh,'type','patch');
% set(lc,{'markersize'},ss,{'cdata'},cm);

% % Plot first dataset.
% plot3(score(gVec==1,1),score(gVec==1,2),score(gVec==1,3),'xr');
% 
% if gNum>=2
%     hold on;
%     plot3(score(gVec==2,1),score(gVec==2,2),score(gVec==2,3),'xg');
% end
% 
% if gNum>=3
%     plot3(score(gVec==3,1),score(gVec==3,2),score(gVec==3,3),'xb');
% end
% 
% hold off;

% %% Dendrogram.
% figure;
% z=linkage(dfms,'ward','correlation');
% gVecStr=num2str(gVec);
% h=dendrogram(z,0,'labels',gVecStr);
% 

%% Hierarchical.

% T=clusterdata(dfms,'maxclust',4,'distance','correlation','linkage','ward');

dfms=zscore(dfms);
z=linkage(pdist(dfms),'ward');
figure;
gVecStr=num2str(gVec);
dendrogram(z,0,'labels',gVecStr);
% T=clusterdata(dfms,'maxclust',4,'linkage','ward');
T=cluster(z,'maxclust',4);

% T=clusterdata(dfms,'maxclust',4,'linkage','ward');
% T=cluster(z,'maxclust',4);
% % X=zscore(dfms);

figure;
hold on;
xlabel('bbLen');
ylabel('bbWidth');
zlabel('bbTipWidth');
gNum=max(gVec);
%%%
h1=scatter3(dfms(gVec==1,1),dfms(gVec==1,2),dfms(gVec==1,3),100,T(gVec==1),'Marker','o');
scatter3(dfms(gVec==1,1),dfms(gVec==1,2),dfms(gVec==1,3),30,T(gVec==1),'filled');
h2=scatter3(dfms(gVec==2,1),dfms(gVec==2,2),dfms(gVec==2,3),100,T(gVec==2),'Marker','s');
scatter3(dfms(gVec==2,1),dfms(gVec==2,2),dfms(gVec==2,3),30,T(gVec==2),'filled');
legend([h1 h2],gnames{1},gnames{2});
if gNum>=3
    h3=scatter3(dfms(gVec==3,1),dfms(gVec==3,2),dfms(gVec==3,3),100,T(gVec==3),'Marker','d');
    scatter3(dfms(gVec==3,1),dfms(gVec==3,2),dfms(gVec==3,3),30,T(gVec==3),'filled');
    legend([h1 h2 h3],gnames{1},gnames{2},gnames{3});
end
if gNum>=4
    h4=scatter3(dfms(gVec==4,1),dfms(gVec==4,2),dfms(gVec==4,3),100,T(gVec==4),'Marker','p');
    scatter3(dfms(gVec==4,1),dfms(gVec==4,2),dfms(gVec==4,3),30,T(gVec==4),'filled');
    legend([h1 h2 h3 h4],gnames{1},gnames{2},gnames{3},gnames{4});
end

%%%
% h1=scatter3Wcf(dfms(T==1,1),dfms(T==1,2),dfms(T==1,3),200,gVec(T==1),'filled');
% h2=scatter3Wcf(dfms(T==2,1),dfms(T==2,2),dfms(T==2,3),200,gVec(T==2),'filled');
% h11=scatter3Wcf(0,0,0,0,1);
% h12=scatter3Wcf(0,0,0,0,2);
% set(h1,'Marker','o');
% set(h2,'Marker','s');
% legend([h1 h2 h11 h12],'Class 1','Class 2',gnames{1},gnames{2});
% if gNum>=3
%     h3=scatter3Wcf(dfms(T==3,1),dfms(T==3,2),dfms(T==3,3),200,gVec(T==3),'filled');
%     h13=scatter3Wcf(0,0,0,0,3);
%     set(h3,'Marker','d');
%     legend([h1 h2 h3 h11 h12 h13],'Class 1','Class 2','Class 3',gnames{1},gnames{2},gnames{3});
% end
% if gNum>=4
%     h4=scatter3Wcf(dfms(T==4,1),dfms(T==4,2),dfms(T==4,3),200,gVec(T==4),'filled');
%     h14=scatter3Wcf(0,0,0,0,4);
%     set(h4,'Marker','h');
%     legend([h1 h2 h3 h4 h11 h12 h13 h14],'Class 1','Class 2','Class 3','Class 4',gnames{1},gnames{2},gnames{3},gnames{4});
% end

hold off;
axis tight;
grid on;
view(3);

% T=clusterdata(score,'maxclust',2,'distance','correlation','linkage','ward');
% X=score;
% figure;
% scatter3(X(:,1),X(:,2),X(:,3),100*T,gVec,'filled');

end