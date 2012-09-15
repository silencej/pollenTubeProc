function [peaks locs]=wavePick(x,ssFlag,debugFlag)
% ssFlag: small sample flag. Then the x_out_mad and x_out_med are globally
% equal.
%	wavePick is free software: you can redistribute it and/or modify
%	it under the terms of the GNU General Public License as published by
%	the Free Software Foundation, either version 3 of the License, or
%	(at your option) any later version.
%	
%	It is distributed in the hope that it will be useful,
%	but WITHOUT ANY WARRANTY; without even the implied warranty of
%	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%	GNU General Public License for more details.
%	
%	You should have received a copy of the GNU General Public License
%	along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
%
%	Initialized by David Damm.
%	Modified and mantained by Chaofeng Wang.
%
%	Website - https://github.com/silencej/ivfcWavePicker
%
%	Copyright, 2011, 2012 Chaofeng Wang <owen263@gmail.com>

%% Settings.
devCoef=1; % Used in thresholding. seekthresh_pos = x_out_med + devCoef * x_out_dev.

if nargin<2
    ssFlag=1;
end

% Added for comparison.
if nargin<3
	debugFlag=true;
end


%% Preprocessing, unbiasing.
% bias = median(abs(x));
xOri = x;
bias = median(x);
x = x - bias;
x = x ./ max(x);

if debugFlag
	close all;
	figure;
%	title(dcfpathname);
%	 plot(t,x_in, 'Color', [.075 .125 .075]);
%	plot(t,x_in,'-k');
	plot(x,'-k');
end

%% Wavelet-based Denoising.
wname = 'sym7';%'coif3';%'sym4';%'db4';
wlevel = 3;
[c, l] = wavedec(x, wlevel, wname);

d_1=detcoef(c,l,1);
% delta_mad is an estimate of the std (or say sigma) of noise.
delta_mad = mad(d_1,1) / .6745; % mad(x,1) for median absolute value. mad(x,0) for mean absolute value.

% From Matlab Doc of mad function:
% different scale estimates: std < mean absolute < median absolute (< stands for worse than in robustness).
% For normally distributed data, multiply mad by one of the following factors to obtain an estimate of the normal scale parameter Ïƒ, e.g. std:
% sigma = 1.253*mad(X,0) â€?For mean absolute deviation
% sigma = 1.4826*mad(X,1) â€?For median absolute deviation
% 1.4826*0.6745=1

% The threshold is different from Dohono1995's - thre = delta * sqrt(2*logn/n). But the original is thre = delta * sqrt(logn). I think it's wrong.
% While in matlab wavelet Fixed Form thresholding, t=s*sqrt(2log(n)).
% Use Donoho's formula will get a threshold near 0! So use matlab formula instead.
% tau = delta_mad * sqrt(log(length(x))); % estimated noise boundary.
n=length(x);
% tau = delta_mad * sqrt(2*log(n)/n);
tau = delta_mad * sqrt(2*log(n));
threshtype = 's';
% Apply the same threshold on all 3 scale details.
nc = wthresh(c, threshtype, tau);
% Stretch to keep the height unchanged after soft-thresholding.
if threshtype == 's'
	x_out = (1 + tau) * waverec(nc, l, wname);
else
	x_out = waverec(nc, l, wname);
end
if debugFlag
	hold on;
	plot(x_out, 'g'); % green.
	hold off;
end

%% Show the effect of soft thresholding.
% figure, plot(nc,'-b');
% hold on;
% plot(c,'-k');
% xl=xlim;
% plot(xl,[tau tau],'--r');
% plot(xl,[-tau -tau],'--r');
% hold off;


%% Peak detection.

l=length(x);
if ssFlag
    x_out_med=ones(l,1)*median(x);
    x_out_mad=ones(l,1)*mad(x,1);
else
    x_out_med=zeros(l,1);
    x_out_mad=zeros(l,1);
    winLen=1000;
    r=floor(winLen/2);
    if size(x,1)>1
        x=x';
    end
    xPad=[x(1+r:-1:2) x x(end:-1:end-r)];
    x=x';
    for k = r+1:l+r
        x_out_med(k-r)=median(xPad(k-r : k + r));
        x_out_mad(k-r)=mad(xPad(k-r : k + r),1);
    end
end
x_out_dev=1.4826 * x_out_mad;
clear x_out_mad;

% look at slope changes
dx = diff(x_out);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% wcf's code.

dx=reshape(dx,length(dx),1);
dx=[0; dx];

seekthresh_pos = x_out_med + devCoef * x_out_dev;
% seekthresh_neg = x_out_med - x_out_dev;
seekthresh_neg = -1 .* seekthresh_pos;
clear x_out_med;
clear x_out_dev;

% Variables;
as=0; % ascent
ds=0; % descent
% state enums: 1-a1, 2-a2, 3-a3, 4-p1, 5-d1, 6-d2.
state=1;
candidate=0;
% peaks=zeros(2,1);
locs=zeros(2,1);
peakNum=0;
	
for i=1:length(dx)
	if dx(i)<=0
		ds=ds+dx(i);
		switch state
			case 1
				state=1; as=0; ds=0;
			case 2
				state=3;
			case 3
				state=1; as=0; ds=0;
			case 4
				state=5;
			case 5
			  if (ds<=seekthresh_neg(i))
				state=6; peakNum=peakNum+1; locs(peakNum)=candidate;
			  else
				state=5;
			  end
			case 6
				state=1; as=0; ds=0;
			otherwise
				fprintf(0,'Unknown state in %d: %s\n', i,state);
		end
	else % dx >0.
		as=as+dx(i);
		switch state
			case 1
				state=2;
			case 2
			  if (as>=seekthresh_pos(i))
				state=4; candidate=i; as=0; ds=0;
			  else
				state=2;
			  end
			case 3
				state=2;
			case 4
				state=4; candidate=i; as=0; ds=0;
			case 5
				state=5;
				% Modify the bug in previous version of FSA in conference paper.
				if x_out(i)>x_out(candidate)
					candidate=i;
				end
			case 6
				state=2;
			otherwise
				fprintf(0,'Unknown state in %d: %s\n', i,state);
		end
	end
end

% Deblurring.
% compare peak_i and peak_i+1, move the higher one to peak_i+1 and put
% peak_i quenched to 0.

deblurWinLen=25; % unit: points.
for i=1:length(locs)-1
    % If locs doesn't change, then locs is zeros(2,1). Or there is only 1
    % peak, then locs(2)==0.
    if ~locs(i) || ~locs(i+1)
        break;
    end
	if locs(i+1)-locs(i)<deblurWinLen
		if x_out(locs(i+1))>x_out(locs(i))
			locs(i)=0;
		else
			locs(i+1)=locs(i);
			locs(i)=0;
		end
		peakNum=peakNum-1;
	end
end

locs=locs(locs~=0);
peaks=xOri(locs);

% if debugFlag
%	 plot(t,dx, ':', 'Color', [.25 .25 .25]);
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if debugFlag
	hold on;
%	 plot(t,x_out_med, '-', 'Color', [0 .25 .5]);
	plot(seekthresh_pos, '--m');
    plot(seekthresh_neg, '--c');
%	 plot(t,x_out_med - x_out_dev, '--', 'Color', [0 0 .25]);
	hold off;
	hold on;
	stem(locs, x(locs), 'or');
	hold off;
    legend('Normalized','Smoothed','Upper Threshold','Lower Threshold','Peaks Picked');
end


end