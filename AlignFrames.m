function [X, Y, Theta, XH, YH, ThetaH, ErrH] = AlignFrames(nVid, params)
% create object to read video
videoInfo = VideoReader(params.pathVideos{nVid});
temp = imread(params.tempPath);
% if no background is defined assume a white background
if params.pathBck == ' '
    bckImg = uint8(255*ones(videoInfo.Width, videoInfo.Height));
else
    bckImg = imread(params.pathBck);
end
bckImg = imgaussfilt(squeeze(bckImg(:,:,1)),16);
% initialize output variables
numFrames = floor(videoInfo.Duration*videoInfo.FrameRate);
X = zeros(numFrames,1);
Y = zeros(numFrames,1);
Theta = zeros(numFrames,1);
XH = zeros(numFrames,1);
YH = zeros(numFrames,1);
ThetaH = zeros(numFrames,1);
ErrH = zeros(numFrames,1);
videoInfo.CurrentTime = 1/videoInfo.FrameRate;
disp(['Initialized Processor ' num2str(nVid)])
for i = 1 : numFrames
    if hasFrame(videoInfo) && videoInfo.CurrentTime < videoInfo.Duration
        try
            % load frame
            frame = readFrame(videoInfo, 'native');
            FRaw = frame(:,:,1);
            FRawSmooth = imgaussfilt(FRaw,16);
            % adjust properties of the background based on properties of
            % the frame
            [bckImg] = AdjustBackground(bckImg,FRawSmooth);
            % track the position and orientation of the body
            [alignedImageBS, ~, P1, P2] = TrackBody(FRaw,FRawSmooth,bckImg);
            % segment head twice with 0 and 180 rotation 
            [SegHead1] = SegmentHead(alignedImageBS);
            [SegHead2] = SegmentHead(imrotate(alignedImageBS,180));
            % adjust head template based on properties of the frame
            [Itemp] = ResizeTemplate(temp, SegHead1);
            % template matching of the head twice with 0 and 180 rotation
            [~, ~, ~, thetaTemp, ~] = AlignHeadImage(Itemp, Itemp, 0, Itemp);
            [~, X1, Y1, theta1, errors1] = AlignHeadImage(SegHead1, Itemp, 0, SegHead1);
            theta1 = theta1-thetaTemp;
            [Itemp] = ResizeTemplate(temp, SegHead2);
            [~, X2, Y2, theta2, errors2] = AlignHeadImage(SegHead2, Itemp, 0, SegHead2);
            theta2 = theta2-thetaTemp;
            % keep the value that provides the lowest matching error 
            if(errors1(3) < errors2(3))
                X(i) = P1(1);
                Y(i) = P1(2);
                Theta(i) = P1(3);
                XH(i) = X1;
                YH(i) = Y1;
                ThetaH(i) = theta1;
                ErrH(i) = errors1(3);
            else
                X(i) = P2(1);
                Y(i) = P2(2);
                Theta(i) = P2(3);
                XH(i) = X2;
                YH(i) = Y2;
                ThetaH(i) = theta2;
                ErrH(i) = errors2(3);
            end
            % output progress every 250 frames
            if mod(i,250) == 0
                fprintf(1,'\t Processor #%2i, Image #%7i of %7i\n', nVid,i,numFrames);
            end          
        catch
            % in case of error keep previous frame output values
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
            if mod(i,250) == 0
                fprintf(1,'\t Processor #%2i, Image #%7i of %7i\n', nVid,i,numFrames);
            end
            % advance for next frame
            videoInfo.CurrentTime = videoInfo.CurrentTime + 1/videoInfo.FrameRate;
        end

    else
        % break when video finishes
        disp(['Processor ' num2str(nVid) ' Closed'])
        break;
    end
end
end