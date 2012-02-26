function len=getEuLen(bbSubs,si,ei)
% Get the eucledian distance from the bbSubs between si and ei.

if si>ei
    tempi=si;
    si=ei;
    ei=tempi;
end

diag=sqrt(2);
subsPart=bbSubs(si:ei,:);
rowDiff=diff(subsPart(:,1));
colDiff=diff(subsPart(:,2));
andVec=rowDiff & colDiff;
diagNum=length(find(andVec));

len=diagNum*diag+length(rowDiff)-diagNum;

end