%% Function to adjust the intensity of the background image based on the original frame average intensity
function [bckImg] = AdjustBackground(bckImg,FRawSmooth)
divv = 8;
% calculate the subsampled average intensity of frame and background
avFrameMat = zeros(divv,divv);
avBckMat = zeros(divv,divv);
for i = 1 : divv
    for j = 1 : divv
        avFrameMat(i,j) = mean(mean(FRawSmooth(1+(i-1)*(size(FRawSmooth,1)/divv):i*(size(FRawSmooth,1)/divv),...
            1+(j-1)*(size(FRawSmooth,2)/divv):j*(size(FRawSmooth,2)/divv))));
        avBckMat(i,j) = mean(mean(bckImg(1+(i-1)*(size(bckImg,1)/divv):i*(size(bckImg,1)/divv),...
            1+(j-1)*(size(bckImg,2)/divv):j*(size(bckImg,2)/divv))));
    end
end
% fing the most matching patch of the image (not to capture the fly)
[~,ix] = min(min(avFrameMat-avBckMat));
[~,iy] = min(min(avFrameMat-avBckMat,[],2));
ix = max(ix,2);
iy = max(iy,2);
avFrameMat(iy-1:iy+1,ix-1:ix+1) = nan;
avBckMat(iy-1:iy+1,ix-1:ix+1) = nan;
% adjust background based on average intensity of the frame
exBrig = - nanmean(nanmean(avBckMat)) + nanmean(nanmean(avFrameMat));
bckImg = bckImg + exBrig;
end

