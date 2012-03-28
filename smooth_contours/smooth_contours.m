function [Xs Ys]=smooth_contours(X, Y, Radius)
% Smooth the contours.
% Modification by Chaofeng Wang: mirror the edge points and pad them on so the copy-on-edge strategy is not needed.
%
% Copyright (c) 2012, Chaofeng Wang
% Copyright (c) 2011, Tolga Birdal
% Copyright (c) 2010, Andrey Sokolov

Xs=zeros(length(X),1);
Ys=zeros(length(X),1);

% Pad the mirrored edge points onto both ends.
if size(X,1)>1
	X=reshape(X,1,length(X));
end
if size(Y,1)>1
	Y=reshape(Y,1,length(Y));
end

X=[X(1+Radius:-1:2) X X(end:-1:end-Radius)];
Y=[Y(1+Radius:-1:2) Y Y(end:-1:end-Radius)];

% % copy out-of-bound points as they are
% Xs(1:Radius)=X(1:Radius);
% Ys(1:Radius)=Y(1:Radius);
% Xs(length(X)-Radius:end)=X(length(X)-Radius:end);
% Ys(length(X)-Radius:end)=Y(length(X)-Radius:end);

% obtain the bounding box
maxX=max(max(X));
minX=min(min(X));
maxY=max(max(Y));
minY=min(min(Y));

% smooth now
for i=Radius+1:length(X)-Radius
	ind=(i-Radius:i+Radius);
	xLocal=X(ind);
	yLocal=Y(ind);
	
	% local regression line
	%p=polyfit(xLocal,yLocal,1);
	[a b c] = wols(xLocal,yLocal,gausswin(length(xLocal),5));
	p(1)=-a/b;
	p(2)=-c/b;
	
	% project point on local regression line
	[x2, y2]=project_point_on_line(p(1), p(2), X(i), Y(i));
	
	% check erronous smoothing
	% points should stay inside the bounding box
	if (x2>=minX && y2>minY && x2<=maxX && y2<=maxY)
		Xs(i-Radius)=x2;
		Ys(i-Radius)=y2;
	else
		Xs(i-Radius)=X(i);
		Ys(i-Radius)=Y(i);
	end
end

end

% Projects the point (x1, y1) onto the line defined as y=m1*x+b1
function [x2, y2]=project_point_on_line(m1, b1, x1, y1)

m2=-1./m1;
b2=-m2*x1+y1;
x2=(b2-b1)./(m1-m2);
y2=m2.*x2+b2;

end

function [a b c] = wols(x,y,w)
% Weighted orthogonal least squares fit of line a*x+b*y+c=0 to a set of 2D points with coordiantes given by x and y and weights w
n = sum(w);
% meanx = sum(w.*x)/n;
meanx = (w'*x')/n; % Gausswin is col and x is row. Now w'*x' will be a scalar dot product.
% meany = sum(w.*y)/n;
meany = w'*y'/n;
x = x - meanx;
y = y - meany;
% y2x2 = sum(w.*(y.^2 - x.^2));
y2x2 = w'*(y.^2 - x.^2)';
% xy = sum(w.*x.*y);
xy = sum(w'*x'*y);
alpha = 0.5 * acot(0.5 * y2x2 / xy) + pi/2*(y2x2 > 0);
%if y2x2 > 0, alpha = alpha + pi/2; end
a = sin(alpha);
b = cos(alpha);
c = -(a*meanx + b*meany);
end

