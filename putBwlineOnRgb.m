function imgOut=putBwlineOnRgb(img,bw)
% imgOut=putBwlineOnRgb(img,bw)
% bw should be a linear bw image.

tempLayer=img(:,:,1); % Layer for temp use.
tempLayer(bw)=255;
imgOut(:,:,1)=tempLayer;
tempLayer=img(:,:,2); % oriPart 1 layer for temp use.
tempLayer(bw)=255;
imgOut(:,:,2)=tempLayer;
tempLayer=img(:,:,3); % oriPart 1 layer for temp use.
tempLayer(bw)=255;
imgOut(:,:,3)=tempLayer;

end