function [dis,npiv]=nearestPoc(spv,curve,scale) % Nearest point on curve.
% spv: start point vector.
% curve: the target curve.
% The function finds for each point in spv its nearest point on the curve, returns the distance in dis, and the index of the nearest point in the curve. So length(dis)==length(npiv)==size(spv,1)~=size(curve,1).

% npiv=zeros(length(x)-2*r,1);

if nargin<3
    scale=20;
end

sr=20; % Search radius on curve. Default in 20X scale.
sr=scale/20*sr;

if size(curve,1)<=2*sr
	npiv=[];
	dis=[];
end

npiv=zeros(size(spv,1),1);
dis=zeros(size(spv,1),1);
for i=1:size(spv,1)
	if i<sr+1
		disVec=sqrt((curve(1:i+sr,1)-spv(i,1)).^2+(curve(1:i+sr,2)-spv(i,2)).^2);
		[mv mi]=min(disVec);
		dis(i)=mv;
		npiv(i)=mi;
	elseif i>size(curve,1)-sr
		disVec=sqrt((curve(i-sr:end,1)-spv(i,1)).^2+(curve(i-sr:end,2)-spv(i,2)).^2);
		[mv mi]=min(disVec);
		dis(i)=mv;
		npiv(i)=i-sr-1+mi;
	else
		disVec=sqrt((curve(i-sr:i+sr,1)-spv(i,1)).^2+(curve(i-sr:i+sr,2)-spv(i,2)).^2);
		[mv mi]=min(disVec);
		dis(i)=mv;
		npiv(i)=i-sr-1+mi;
	end
end
