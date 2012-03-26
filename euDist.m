function dis=euDist(sp,ep)
% Calculate the Eucledian distance.
% sp: start point. ep: end point.
% UPDATE: now the sp and ep could be matrices of size N * 2, [row col].

dis=sqrt( (sp(:,1)-ep(:,1)).^2 + (sp(:,2)-ep(:,2)).^2 );
% dis=norm(sp-ep);
% 
% V = G - G2;
% D = sqrt(V * V');

% Ref:
% http://www.mathworks.com/matlabcentral/answers/2849-euclidean-distance-of-two-vectors


end
