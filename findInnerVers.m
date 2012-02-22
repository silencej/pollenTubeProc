function innerVertices=findInnerVers(A,si,ei)
% Find the inner vertices on the path si->ei. The "A" is adjacency matrix.
% "innerVertices": column vectors of inner ver indecies.
% It's a recursion on Floyd algrithm.

D=fastFloyd(A);
innerVertices=zeros(10,1);
pt=0;

while si~=ei
	nbrs=find(A(si,:)~=inf);
	minDist=inf;
	for i=1:length(nbrs)
		if D(nbrs(i),ei)<minDist
			si=nbrs(i);
			minDist=D(nbrs(i),ei);
		end
	end
	if si~=ei
        pt=pt+1;
		innerVertices(pt)=si;
	end
end

innerVertices=innerVertices(innerVertices~=0);
% if isempty(innerVertices)
% 	innerVertices=0;
% end

end
