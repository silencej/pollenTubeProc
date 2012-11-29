function testWavy

%%
bw=imread('200G.pbm');
bw=bw~=0;
% bw=parsiSkel(bw);


% [subMatrix labelNum skelImg bubbles tips lbbImg lbbLen
% lbbSubs]=decomposeSkel(bw,sp,1,5,[],1);
lbbSubs=getBbSubs(bw);

x=lbbSubs(:,2);
y=lbbSubs(:,1);
addpath('smooth_contours');
r=201;

% for i=1:3
% end

[xs ys]=smooth_contours(x, y, r);


%%

[dev npiv]=nearestPoc([x y],[xs ys]); % Nearest point on curve.
if isempty(dev)
    error('Curve too short to do nearestPoc.');
end

%% TODO: make smooth_contour smooth the edges either.

% First cmp y, then cmp x, if contour>sContour, then the sign is +,
% else -.
%    dev=euDist([y x],[ys xs]); % Deviation from the center line.
%    signs=sign(y-ys);
signs=sign(y-ys(npiv));
%    xd=x-xs;
xd=x-xs(npiv);
signs(signs==0)=sign(xd(signs==0));
dev=dev.*signs;
% wavyCoef=sum(abs(dev))/lbbLen;

%     [C,L] = wavedec(dev,3,'sym7');
%     sDev = wden(dev,'rigrsure','s','mln',3,'sym7');
% 	sWin=30; % Smooth window.
% 	sWin=sWin*handles.scale/20;
[pks locs]=wavePick(abs(dev),1,0);
%     [pks,locs]=findpeaks(filtfilt(1/sWin*ones(sWin,1),1,abs(dev)));
%     [pks,locs]=findpeaks(sDev);
wavyPkThre=5; % Default ther in 20X scale.
% wavyPkThre=wavyPkThre;
wavyNum=length(find(pks>wavyPkThre));
fprintf(1,'Waviness number = %d.\n',wavyNum);
%     if 1
pLocs=find(pks>wavyPkThre);

figure('name','Wavy Points Picked'), plot(x,y,'-k');
hold on;
plot(xs,ys);
plot(x(locs(pLocs)),y(locs(pLocs)),'or');
plot(xs(npiv(locs(pLocs))),ys(npiv(locs(pLocs))),'.r');
axis image;
xlabel('Image pixel');
ylabel('Image pixel');
legend('Original Curve','Center Line','Wavy Point','Correspond Point on Center line');


end

function bbSubs=getBbSubs(skel)

global gImg;

sp=findEndPoint(skel);

gImg=skel;

% bbImg=gImg;

% Get subs from the backbone image.

% backbone pixel number, which is always integer, different from bbLen.
bbPnum=length(find(gImg(:)));
bbSubs=zeros(bbPnum,2);

gImg(sp(1),sp(2))=0;
len=1;
bbSubs(len,:)=sp;
nbr1=nbr8(sp);
while nbr1(1)~=0
    if size(nbr1,1)~=1
        % When Ren-shape joint is met, first trace to its 4-nbr, then 8-nbr.
        nbr1=nbr1(1,:);
    end
    
    gImg(nbr1(1),nbr1(2))=0;
    len=len+1;
    bbSubs(len,:)=nbr1;
    %	 sp=nbr1;
    nbr1=nbr8(nbr1);
end

% Clean 0 out of bbSubs.
bbSubs=bbSubs(bbSubs(:,1)~=0,:);

end