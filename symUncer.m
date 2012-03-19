function su=symUncer(x,y)
% Symmetric uncertainty.
% SU(X,Y)=2(IG(X|Y)/ (H(X)+H(Y)) ).
% IG(X|Y)=H(X)-H(X|Y).
% Reference: Yu2004Feature.

addpath('mrmr/mi_0.9');

enx=entropy(x);
ig=enx-condentropy(x,y);
su=2*(ig/(enx-entropy(y)));

