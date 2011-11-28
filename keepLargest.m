function bw=keepLargest(bw,nbrWay)
% bw=keepLargest(bw,nbrWay)
% Keep the largest connected component.
% If nbrWay is not input, the connectness is based on 4-way neighbouring.

if nargin<2
    nbrWay=4;
end

if nbrWay>=8
    nbrWay=8;
else
    nbrWay=4;
end

ver=getVersion;

if ver<=7.5 % matlab 2007b is 7.5.0.
    [L,Num]=bwlabeln(bw,nbrWay);
    ll=zeros(Num,1);
    for j=1:Num
        ll(j)=length(find(L==j));
    end
    [mv mi]=max(ll);
    bw=(L==mi);
else
    % Matlab newer version is required!
    % Matlab said: bwconncomp uses less memory and sometimes faster.
    CC=bwconncomp(bw,nbrWay);
    ll=zeros(CC.NumObjects,1);
    for j=1:CC.NumObjects
        ll(j)=length(CC.PixelIdxList{j});
    end
    [mv mi]=max(ll);
    bw=zeros(size(bw));
    bw(CC.PixelIdxList{mi})=1;
    bw=(bw~=0);
end

end