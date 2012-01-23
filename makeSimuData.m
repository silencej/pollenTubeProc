function makeSimuData

clear global;
clear all;
close all;

dataDir='./simuData';
if ~exist(dataDir,'dir')
	mkdir(dataDir);
end

% Pollen grain radius: constant.
% Backbone width, len: n(mu,sigma).
% Branching distance, bubble distance, : n(mu,sigma).

%% Constants.
% Image.
imgWidth=800;
imgHeight=800;
% Pollen Grain. [row col radius].
grain=[50 50 20];
% Generate 10 images for each type.
imgNum=10;
% cutMargin=50;

%% Variables.

className='B';

% NOTE: bbWidth, bbLen are vectors!
% bbWidth=normrnd(20,2,imgNum,1);
% bbLen=normrnd(500,10,imgNum,1);
bbWidth=random('unif',15,25,imgNum,1);
bbLen=random('unif',600,700,imgNum,1);
% brWidth=bbWidth;
% branchDisMu=200;
% branchDisSigma=20;
branchDisMin=100;
branchDisMax=150;
% brLenMu=300;
% brLenSigma=10;
brLenMin=290;
brLenMax=310;
% bubbleDisMu=300;
% bubbleDisSigma=10;
bubbleDisMin=500;
bubbleDisMax=600;
% bubbleRadMu=50;
% bubbleRadSigma=10;
bubbleRadMin=20;
bubbleRadMax=40;
bubbleNum=0;

%%

for i=1:imgNum
	img=zeros(imgHeight,imgWidth);
	img=img~=0;

    bubbles=zeros(30,3); % [row, col, radius].    

	% Plot backbone.
	img(grain(1),grain(2):grain(2)+floor(bbLen(i)))=1;

    % Collect bubbles on backbone.
    presentPos=grain(2);
% 	presentPos=floor(presentPos+normrnd(bubbleDisMu,bubbleDisSigma));
    presentPos=floor(presentPos+random('unif',bubbleDisMin,bubbleDisMax));
% 	bubbleRad=normrnd(bubbleRadMu,bubbleRadSigma);
    bubbleRad=random('unif',bubbleRadMin,bubbleRadMax);
    while presentPos<grain(2)+bbLen(i)
		bubbleNum=bubbleNum+1;
		bubbles(bubbleNum,:)=[grain(1) presentPos bubbleRad];
        bubbleDis=random('unif',bubbleDisMin,bubbleDisMax);
		presentPos=floor(presentPos+bubbleDis);
		bubbleRad=random('unif',bubbleRadMin,bubbleRadMax);
    end

    % Branching.
	presentPos=grain(2);
	branchDis=random('unif',branchDisMin,branchDisMax);
	presentPos=floor(presentPos+branchDis);
	while presentPos<grain(2)+bbLen(i)
		brLen=random('unif',brLenMin,brLenMax);
		% Plot branches.
		img(grain(1):grain(1)+floor(brLen),presentPos)=1;

		presentVPos=grain(1); % present vertical pos.
%         bubbleDis=normrnd(bubbleDisMu,bubbleDisSigma);
        bubbleDis=random('unif',bubbleDisMin,bubbleDisMax);
        presentVPos=floor(presentVPos+bubbleDis);
% 		bubbleRad=normrnd(bubbleRadMu,bubbleRadSigma);
        bubbleRad=random('unif',bubbleRadMin,bubbleRadMax);
        while bubbleDis>0 && presentVPos<grain(1)+brLen;
%             disp('-----------------------');
%             disp(presentVPos);
			bubbleNum=bubbleNum+1;
			bubbles(bubbleNum,:)=[presentVPos presentPos bubbleRad];
%             bubbleDis=normrnd(bubbleDisMu,bubbleDisSigma);
            bubbleDis=random('unif',bubbleDisMin,bubbleDisMax);
			presentVPos=floor(presentVPos+bubbleDis);
% 			bubbleRad=normrnd(bubbleRadMu,bubbleRadSigma);
            bubbleRad=random('unif',bubbleRadMin,bubbleRadMax);
        end
        
%         branchDis=normrnd(branchDisMu,branchDisSigma);	
        presentPos=floor(presentPos+branchDis);

	end
	% bubbleDis=normrnd(100,100);

	% Screeze 0 rows out from bubbles.
	bubbles=bubbles((bubbles(:,1)~=0),:);

	% Dilation.
    % strel('disk',R,0) will generate a full circle.
% 	img=imdilate(img,strel('disk',floor(bbWidth(i)),0));
  	img=imdilate(img,strel('disk',floor(bbWidth(i))) );

	% Put Bubbules.
    for j=1:size(bubbles,1)
		tempImg=zeros(size(img));
		tempImg(bubbles(j,1),bubbles(j,2))=1;
		tempImg=imdilate(tempImg,strel('disk',floor(bubbles(j,3)),0));
		img=img | tempImg;
    end
    
    % Plot grain.
    tempImg=zeros(size(img));
    tempImg(grain(1),grain(2))=1;
    tempImg=imdilate(tempImg,strel('disk',floor(grain(3)),0));
    img=img | tempImg;
    
	imwrite(img,['./simuData/' className num2str(i) '.png']);
end


