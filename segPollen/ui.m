function ui(img0)

close all;

global img fH;

if nargin==0
    img=imread('../../data/guanPollen/G11-1.tif');
    img=imcomplement(img);
else
    img=img0;
    clear img0;
end
    
% img=imadjust(img);

fH=figure;
% pos=get(fH,'Position');
set(fH,'Position',[20 20 700 600],'Toolbar','figure');
% imshow(img,[]);
maxV=intmax(class(img));
% maxV=6553500;
editUi=uicontrol('Style','edit','Position',[530 20 80 20],'String','Caling...');
thre=pgThre(0,0,editUi);
sliderUi=uicontrol('Style', 'slider',...
        'Min',0,'Max',maxV,'Value',thre,...
        'Position', [400 20 120 20],...
        'SliderStep',[1/double(maxV),10/double(maxV)],...
        'Callback', {@pgThre,editUi});
set(editUi,'Callback',{@pgThreEdit,sliderUi});


% %%
% % vlfeat fails to find the pollen grains.
% 
% % a = fileparts(mfilename('fullpath'));
% % % [a,b,c] = fileparts(a);
% % root = a;
% % addpath(fullfile(root,'vlfeat','toolbox'));
% 
% run('vlfeat/toolbox/vl_setup');
% 
% 
% figure,imshow(img,[]);
% eh=imellipse;
% pos=wait(eh); % [tlRow tlCol width height], tl: top left.
% % tempImg=ellipCrop(img,pos);
% mask=poly2mask(pos(:,1),pos(:,2),size(img,1),size(img,2));
% tempImg = bsxfun(@times, double(img), double(mask));
% figure,imshow(tempImg,[]);
% tempImg(tempImg==0)=2800;
% 
% % close all;
% % figure,imagesc(img);
% % colormap gray;
% hold on;
% [F,D]=vl_sift(im2single(tempImg),'EdgeThresh',15);
% vl_plotframe(F);
% [F2,D2]=vl_sift(im2single(img),'EdgeThresh',15);
% [matches, scores] = vl_ubcmatch(D,D2) ;
% 
% %%
% 
% [drop, perm] = sort(scores, 'descend') ;
% matches = matches(:, perm) ;
% scores  = scores(perm) ;
% 
% figure;
% % imagesc(cat(2, image, Ib)) ;
% imshow(tempImg,[]);
% axis image off ;
% 
% hold on ;
% % xa = F(1,matches(1,:)) ;
% % ya = F(2,matches(1,:)) ;
% % h = line([xa ; xb], [ya ; yb]) ;
% % set(h,'linewidth', 1, 'color', 'b') ;
% vl_plotframe(F(:,matches(1,:))) ;
% 
% figure;
% imshow(img,[]);
% % xb = F2(1,matches(2,:));
% % yb = F2(2,matches(2,:)) ;
% hold on;
% vl_plotframe(F2(:,matches(2,:))) ;
% axis image off ;

end

function setThre(thre)
global img fH;
bw=img>=thre;
[row col]=find(bw);
figure(fH);
imshow(img,[],'Parent',gca);
hold on;
plot(col,row,'.r','Markersize',5);
hold off;
end

function thre=pgThre(hObj,event,editUi)
if ~hObj
    thre=64000;
%     thre=maxV*graythresh(imcomplement(img));
else
    thre=get(hObj,'Value');
end
set(editUi,'String',num2str(thre));
set(editUi,'Enable','off');
if hObj
    set(hObj,'Enable','off');
end
setThre(thre);
% uicontrol('Style', 'slider',...
%         'Min',0,'Max',maxV,'Value',thre,...
%         'Position', [400 20 120 20],...
%         'Callback', {@pgThre,img,fH});
set(editUi,'Enable','on');
if hObj
    set(hObj,'Enable','on');
end
end

function thre=pgThreEdit(hObj,event,sliderUi)
if ~hObj
    thre=1000;
%     thre=maxV*graythresh(imcomplement(img));
else
    thre=get(hObj,'String');
end
thre=str2double(thre);
set(sliderUi,'Value',thre);
set(sliderUi,'Enable','off');
set(hObj,'Enable','off');
setThre(thre);
% uicontrol('Style', 'slider',...
%         'Min',0,'Max',maxV,'Value',thre,...
%         'Position', [400 20 120 20],...
%         'Callback', {@pgThre,img,fH});
set(sliderUi,'Enable','on');
set(hObj,'Enable','on');
end

% function A_cropped=ellipCrop(A,pos)
% 
% %# Create an ellipse shaped mask
% % c = fix(size(A) / 2);   %# Ellipse center point (y, x)
% c=pos(1:2); %# Ellipse center point (y, x)
% r_sq = [pos(4)/2, pos(3)/2] .^ 2;  %# Ellipse radii squared (y-axis, x-axis)
% [X, Y] = meshgrid(1:size(A, 2), 1:size(A, 1));
% ellipse_mask = (r_sq(2) * (X - c(2)) .^ 2 + ...
%     r_sq(1) * (Y - c(1)) .^ 2 <= prod(r_sq));
% 
% %# Apply the mask to the image
% A_cropped = bsxfun(@times, double(A), double(ellipse_mask));
% 
% end
