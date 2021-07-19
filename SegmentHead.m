%% crop a rectangle around the fly's head
function [SegHead, FBSHead] = SegmentHead(alignedImageBS)
% define a box that will contain the full head
s = size(alignedImageBS);
BoxSizeX = 40;
BoxSizeY = 50;
HeadOffsetY = 0;
HeadOffsetX = 80;
HeadBoxX = HeadOffsetX + (s(1)/2-BoxSizeX:s(1)/2+BoxSizeX);
HeadBoxY = HeadOffsetY + (s(2)/2-BoxSizeY:s(2)/2+BoxSizeY);

% crop the frame using the headbox and adjust the contrast
FBSHead = alignedImageBS(HeadBoxX,HeadBoxY);
xb = mean(mean(FBSHead(floor(end/2)-10:floor(end/2)+10,floor(end/2)-10:floor(end/2)+10)));
m = (0.15-0.18)/(43.6-49);
b = (43.6*0.18-49*0.15)/(43.6-49);
yb = xb*m+b+0.1;
FBSHead = imadjust(FBSHead,[0.01 max(0.05,yb)],[],1.5);

% iteratively fill, dilate and erode image until it fills an area
% approximately the size of the fly's head
FEdHead = MaskBody(FBSHead);
FEdHead = edge(FEdHead,'canny',0.1 ,1+sqrt(3));
FEdHead = imfill(FEdHead,'holes');
it = 1;
while(sum(sum(FEdHead)) < 2000 && it  < 10)
    se = strel('square',it);
    FEdHead = imdilate(FEdHead,se);
    FEdHead = imerode(FEdHead,se);
    FEdHead = imdilate(FEdHead,se);
    FEdHead = imfill(FEdHead,'holes');
    FEdHead = imerode(FEdHead,se);
    it = it + 1;
end
% Select the largest connected componnent and mask out all the others
CC = bwconncomp(FEdHead,4);
if length(CC.PixelIdxList) > 1
    lengths = zeros(1,length(CC.PixelIdxList));
    means = zeros(1,length(CC.PixelIdxList));
    for j=1:length(lengths)
        means(j) = mean(FEdHead(CC.PixelIdxList{j}));
        lengths(j) = length(FEdHead(CC.PixelIdxList{j}));
    end
    [~,idx] = max(means);
    if lengths(idx) < 2000
        [~,idx] = max(lengths);
    end
    temp = FEdHead;
    temp(:) = 0;
    temp(CC.PixelIdxList{idx}) = 1;
    mask = temp;
else
    mask = FEdHead;
end
SegHead = immultiply(mask,FBSHead);
end