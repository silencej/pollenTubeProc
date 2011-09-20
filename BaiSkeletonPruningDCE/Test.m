I = imread('carriage-17.GIF');
I = imresize(I,.75);
bw = im2bw(I);
bw= 1-bw; %the shape must be black, i.e., values zero.

[bw,I0,x,y,x1,y1,aa,bb]=div_skeleton_new(4,1,bw,14);

imshow(bw+I0);
hold on
plot(bb, aa, '.r');
plot(y1, x1, 'og');
plot(y, x, '.g');