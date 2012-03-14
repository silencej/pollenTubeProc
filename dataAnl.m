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

dfms=inf(50,12);
dfmsPt=0;
gVec=inf(50,1); % group id vector.
gNum=length(files);
filenames=cell(gNum,1);
for i=1:length(files)
    load(files{i},'dfm','-mat');
    dfmNum=size(dfm,1);
    dfms(dfmsPt+1:dfmsPt+dfmNum,:)=dfm;
    gVec(dfmsPt+1:dfmsPt+dfmNum)=i;
    dfmsPt=dfmsPt+dfmNum;
    [pathname filename extname]=fileparts(files{i});
    sprintf([pathname extname]);
    filenames(i,1)={filename};
end

gVec=gVec(gVec~=inf);
dfms=dfms(1:length(gVec),:);

[coef score]=princomp(zscore(dfms)); % Re-scale variables.
sprintf(num2str(coef(1)));
% gNum=max(gVec);

%% Robust PCA.

% addpath('./libra/');


%% PCA.

figure;
% h=scatter3(score(:,1),score(:,2),score(:,3),100,gVec,'filled');
% h=scatter(score(:,1),score(:,2),100,gVec,'filled');
title('PCA');
% sc=get(h,'children');
% ss=get(sc,'markersize');
% cm=get(sc,'cdata');
hold on;
plot(score(gVec==1,1),score(gVec==1,2),'or','MarkerFaceColor','r');
plot(score(gVec==2,1),score(gVec==2,2),'og','MarkerFaceColor','g');
if gNum==2
    legend(sc,filenames{1},filenames{2});
elseif gNum==3
    plot(score(gVec==3,1),score(gVec==3,2),'ob','MarkerFaceColor','b');
    legend(filenames{1},filenames{2},filenames{3});
elseif gNum==4
    plot(score(gVec==3,1),score(gVec==3,2),'ob','MarkerFaceColor','b');
    plot(score(gVec==4,1),score(gVec==4,2),'oc','MarkerFaceColor','c');
    legend(filenames{1},filenames{2},filenames{3},filenames{4});
end
hold off;
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

%% Dendrogram.
figure;
z=linkage(dfms,'ward','correlation');
gVecStr=num2str(gVec);
h=dendrogram(z,0,'labels',gVecStr);

%% Hierarchical.

T=clusterdata(dfms,'maxclust',2,'distance','correlation','linkage','ward');
X=zscore(dfms);
figure;
h=scatter3(X(:,1),X(:,2),X(:,3),100*T,gVec,'filled');
hstruct = get(h);
if gNum==2
legend(hstruct.Children,filenames{1},filenames{2});
elseif gNum==3
legend(hstruct.Children,filenames{1},filenames{2},filenames{3});
elseif gNum==4
legend(hstruct.Children,filenames{1},filenames{2},filenames{3},filenames{4});
end

T=clusterdata(score,'maxclust',2,'distance','correlation','linkage','ward');
X=score;
figure;
scatter3(X(:,1),X(:,2),X(:,3),100*T,gVec,'filled');

end