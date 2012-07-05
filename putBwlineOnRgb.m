function imgOut=putBwlineOnRgb(img,bw,color)
% imgOut=putBwlineOnRgb(img,bw)
% bw should be a linear bw image.

if nargin<3
    color=[255 255 255];
end

tempLayer=img(:,:,1); % Layer for temp use.
tempLayer(bw)=color(1);
imgOut(:,:,1)=tempLayer;
tempLayer=img(:,:,2); % oriPart 1 layer for temp use.
tempLayer(bw)=color(2);
imgOut(:,:,2)=tempLayer;
tempLayer=img(:,:,3); % oriPart 1 layer for temp use.
tempLayer(bw)=color(3);
imgOut(:,:,3)=tempLayer;

end