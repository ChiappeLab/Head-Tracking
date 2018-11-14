function [alignedImageBS, alignedImageBS2, P1, P2, mig2] = TrackBody(FRaw,FRawSmooth,bckImg)
s = size(FRaw);
img = imadjust(bckImg-FRawSmooth,[],[],1);
img = edge(img,'canny',0.5 ,1+sqrt(3));
mig2 = img;
it = 1;
while(sum(sum(img)) < 6000 && it  < 10)
    se = strel('square',it);
    img = imdilate(img,se);
    img = imerode(img,se);
    img = imdilate(img,se);
    img = imfill(img,'holes');
    img = imerode(img,se);
    it = it + 1;
end
CC = bwconncomp(img,4);
if length(CC.PixelIdxList) > 1
    lengths = zeros(1,length(CC.PixelIdxList));
    means = zeros(1,length(CC.PixelIdxList));
    for j=1:length(lengths)
        means(j) = mean(img(CC.PixelIdxList{j}));
        lengths(j) = length(img(CC.PixelIdxList{j}));
    end
    [~,idx] = max(means);
    if lengths(idx) < 2000
        [~,idx] = max(lengths);
    end
    temp = img;
    temp(:) = 0;
    temp(CC.PixelIdxList{idx}) = 1;
    mask = temp;
else
    mask = img;
end
img = immultiply(mask,img);

% Extract info blob
stats = regionprops(img, 'Orientation','Centroid');
if(isempty(stats))
    clearvars stats
    stats.Centroid(1)=s(2)/2;
    stats.Centroid(2)=s(1)/2;
    stats.Orientation=0;
end
T = affine2d([1 0 0 ;0 1 0; s(2)/2-stats.Centroid(1) s(1)/2-stats.Centroid(2) 1]);
alignedImageBSCent = imwarp(bckImg-FRaw, T,'OutputView', imref2d(s), 'interp', 'linear');
alignedImageBS = imrotate(alignedImageBSCent, -90-stats.Orientation, 'crop');
P1(1) = stats.Centroid(1);
P1(2) = stats.Centroid(2);
P1(3) = stats.Orientation;

alignedImageBSCent2 = imwarp(FRaw, T,'OutputView', imref2d(s), 'interp', 'linear');
alignedImageBS2 = imrotate(alignedImageBSCent2, -90-stats.Orientation, 'crop');

% T = affine2d([1 0 0 ;0 1 0; s(2)/2-stats.Centroid(1) s(1)/2-stats.Centroid(2) 1]);
% alignedImageBSCent = imwarp(bckImg-FRaw, T,'OutputView', imref2d(s), 'interp', 'linear');
% alignedImageBS = imrotate(alignedImageBSCent, -90-stats.Orientation, 'crop');



% Re center info blob (in case 180º off)
centeredImg = imwarp(img, T,'OutputView', imref2d(s), 'interp', 'linear');
aligImg2 = imrotate(centeredImg, -90-stats.Orientation+180, 'crop');
% alignedImageBS2 = imrotate(alignedImageBSCent, -90-stats.Orientation+180, 'crop');
stats2 = regionprops(aligImg2, 'Orientation','Centroid');
if(isempty(stats2))
    clearvars stats2
    stats2.Centroid(1)=s(2)/2;
    stats2.Centroid(2)=s(1)/2;
    stats2.Orientation=0;
end
% T2 = affine2d([1 0 0 ;0 1 0; s(2)/2-stats2.Centroid(1) s(1)/2-stats2.Centroid(2) 1]);
% alignedImageBS2 = imwarp(alignedImageBS2, T2,'OutputView', imref2d(s), 'interp', 'linear');
% 
P2(1) = P1(1) + stats2.Centroid(1);
P2(2) = P1(2) + stats2.Centroid(2);
P2(3) = stats.Orientation;

end

