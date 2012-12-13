function [qlt, scl, rot, xpk, ypk]=houghEllip(src, patt, rhoRange, thetaRange, kwidth)
%
% [qlt, scl, rot, varargout] = GFHT(src, patt, rhorange, thetarange, kwidth, varargin)
% This function implements the generalized fuzzy Hough transform looking 
% for the best pattern mathing on the source image.
%
% src:      source image (bitmap)
% patt:     R-table including the points for the searched pattern
% rhorange: value range for the radius of the pattern
% thetarange: value range for the angle of rotation of the pattern
% kwidth:   kernel width to be considered for the fuzzy transform. It is
%           centered on the feature line to get the fuzzy Hough accumulator
% varargin{1}: debug flag
% qlt:      quality ratio estimated for the best match
% scl:      best pattern scale (rho) for the best match
% rot:      best pattern rotation angle (theta) for the best match
% xpk:      x-axis coordinate for the center of the best matching pattern
% ypk:      y-axis coordinate for the center of the best matching pattern
%
% Copyright (c) 2012 by Chaofeng Wang.

% function [scl, rot, cx, cy]=houghEllipse(eg,rhoRange,thetaRange,)
% [qlt, scl, rot, xpk, ypk] = gfht(src, patt, rhorange, thetarange, kwidth, varargin)


end