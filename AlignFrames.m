function [X, Y, Theta, XH, YH, ThetaH, ErrH] = AlignFrames(nVid, params)
videoInfo = VideoReader(params.pathVideos{nVid});
temp = imread(params.tempPath);
bckImg = imread(params.pathBck);
bckImg = imgaussfilt(squeeze(bckImg(:,:,1)),16);
numFrames = floor(videoInfo.Duration*videoInfo.FrameRate);
X = zeros(numFrames,1);
Y = zeros(numFrames,1);
Theta = zeros(numFrames,1);
XH = zeros(numFrames,1);
YH = zeros(numFrames,1);
ThetaH = zeros(numFrames,1);
ErrH = zeros(numFrames,1);
videoInfo.CurrentTime = 1/videoInfo.FrameRate;%tdebug;%

vidsW = VideoWriter([params.pathVideos{nVid}(1:end-4) 'Crp.avi'], 'Grayscale AVI'); %% change
vidsW.FrameRate = videoInfo.FrameRate;
open(vidsW)
disp('Done P')
for i = 1 : numFrames
    if hasFrame(videoInfo) && videoInfo.CurrentTime < videoInfo.Duration
        try
            frame = readFrame(videoInfo, 'native');
            FRaw = frame(:,:,1);
            FRawSmooth = imgaussfilt(FRaw,16);
            [bckImg] = AdjustBackground(bckImg,FRawSmooth);
            [alignedImageBS, aligImgBS2, P1, P2] = TrackBody(FRaw,FRawSmooth,bckImg);
            [SegHead1] = SegmentHead(alignedImageBS);
            [SegHead2] = SegmentHead(imrotate(alignedImageBS,180));
            [Itemp] = ResizeTemplate(temp, SegHead1);
            [~, ~, ~, thetaTemp, ~] = AlignHeadImage(Itemp, Itemp, 0, Itemp);
            [~, X1, Y1, theta1, errors1] = AlignHeadImage(SegHead1, Itemp, 0, SegHead1);
            theta1 = theta1-thetaTemp;
            [Itemp] = ResizeTemplate(temp, SegHead2);
            [~, X2, Y2, theta2, errors2] = AlignHeadImage(SegHead2, Itemp, 0, SegHead2);
            theta2 = theta2-thetaTemp;
            if(errors1(3) < errors2(3))
                X(i) = P1(1);
                Y(i) = P1(2);
                Theta(i) = P1(3);
                XH(i) = X1;
                YH(i) = Y1;
                ThetaH(i) = theta1;
                ErrH(i) = errors1(3);
                aligImgBS2 = imrotate(aligImgBS2, 180);
            else
                X(i) = P2(1);
                Y(i) = P2(2);
                Theta(i) = P2(3);
                XH(i) = X2;
                YH(i) = Y2;
                ThetaH(i) = theta2;
                ErrH(i) = errors2(3);
            end
            writeVideo(vidsW,aligImgBS2(100:444, 352:672))
            if mod(i,100) == 0
                fprintf(1,'\t Processor #%2i, Image #%7i of %7i\n', nVid,i,numFrames);
            end
%             
%             
        catch
            disp(['Error occured in P' num2str(nVid) ' Frame: ' num2str(i)])
            if i > 1
                X(i) = X(i-1);
                Y(i) = Y(i-1);
                Theta(i) = Theta(i-1);
                XH(i) = XH(i-1);
                YH(i) = YH(i-1);
                ThetaH(i) = ThetaH(i-1);
                ErrH(i) = ErrH(i-1);
            else
                X(i) = nan;
                Y(i) = nan;
                Theta(i) = nan;
                XH(i) = nan;
                YH(i) = nan;
                ThetaH(i) = nan;
                ErrH(i) = nan;
            end
            if mod(i,100) == 0
                fprintf(1,'\t Processor #%2i, Image #%7i of %7i\n', nVid,i,numFrames);
            end
            videoInfo.CurrentTime = videoInfo.CurrentTime + 1/videoInfo.FrameRate;
        end

    else
        disp(['Break P' num2str(nVid)])
        break;
    end
end
close(vidsW)
end