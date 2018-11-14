function [ImgCropped] = CropFrame(frame)
temp = imread('J:\HeadVideos\TempHead.tif');
bckImg = imread('J:\Video Backgrounds\BackgroundDarkApril2018.tif');
bckImg = imgaussfilt(squeeze(bckImg(:,:,1)),16);
FRaw = frame(:,:,1);
FRawSmooth = imgaussfilt(FRaw,16);
[bckImg] = AdjustBackground(bckImg,FRawSmooth);
[alignedImageBS, alignedImageBSI, ~] = TrackBodyRaw(FRaw,FRawSmooth,bckImg);
[SegHead1] = SegmentHead(alignedImageBSI);
[SegHead2] = SegmentHead(imrotate(alignedImageBSI,180));
[Itemp] = ResizeTemplate(temp, SegHead1);
[~, ~, ~, ~, errors1] = AlignHeadImage(SegHead1, Itemp, 0, SegHead1);
[Itemp] = ResizeTemplate(temp, SegHead2);
[~, ~, ~, ~, errors2] = AlignHeadImage(SegHead2, Itemp, 0, SegHead2);
if(errors1(3) < errors2(3))
    alignedImageBS = imrotate(alignedImageBS, 180);
end
% try
ImgCropped = alignedImageBS(100:444, 352:672);
% catch
%     disp('RESf')
% end
end