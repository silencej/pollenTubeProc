function cpout=traceContour(cpin)
% cp: contour points: [col row].
% Make sure cp is strictly 8-connected.

% cpp=1;
global cp;
cp=cpin;
clear cpin;

% Sort in order of the col so searching nearestNbr will be done at row(i-1:i+1) and col(i-1:i+1).
% The order is always i,i+1,i-1.
[col perm]=sort(cp(:,1));
% sprintf(num2str(size(temp,1)));
% clear temp;
row=cp(perm,2);
cp=[col row];

cpout=zeros(size(cp));
cpout(1,:)=cp(1,:);
nbr=findNearestNbr(1);
cpout(2,:)=cp(nbr,:);
cp(1,:)=[0 0];
pt=3;
while pt<size(cp,1)
    nbr2=findNearestNbr(nbr);
    if ~nbr2
        error('Meet 0!');
    end
    cp(nbr,:)=[0 0];
    nbr=nbr2;
    cpout(pt,:)=cp(nbr,:);
    pt=pt+1;
end
cp(nbr,:)=[0 0];
cpout(end,:)=cp(cp(:,1)~=0,:);
end

function outIdx=findNearestNbr(idx)
% If no nearest nbr, outIdx is 0.

global cp;
outIdx=0;

for i=1:size(cp,1)
    if size(cp,1)==1
        return;
    end
    % cp(idx,1)==0 indicates it's been visited.
    if i==idx || ~cp(idx,1)
        continue;
    end
    colDis=abs(cp(i,1)-cp(idx,1));
    rowDis=abs(cp(i,2)-cp(idx,2));
    if  colDis>1 || rowDis>1
        continue;
    end

    outIdx=i;
    return;

end

end