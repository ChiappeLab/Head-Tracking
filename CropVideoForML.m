clear
clc
path = 'J:\HeadVideos\WTTB Mock\';
pathF = dir(path);
pathFlies = pathF(3:end);
for n = 11 : length(pathFlies)
    if exist([path pathFlies(n).name '\AlignOutput2.mat'], 'file') == 2
        dt = load([path pathFlies(n).name '\AlignOutput2.mat']);
        pathVids = cell(dt.params.NProcessors,1);
        pathVidsWrite = cell(dt.params.NProcessors,1);
        for nVid = 1 : dt.params.NProcessors
            pathVids{nVid} = [path pathFlies(n).name dt.params.pathVideos{nVid}(end-7:end)];
            pathVidsWrite{nVid} = [path pathFlies(n).name '\VidCrop' num2str(nVid) '.avi'];
        end
        poolobj = gcp('nocreate');
        if isempty(poolobj)
            parpool(dt.params.NProcessors);
        end
        disp(['START vid ' pathFlies(n).name '\VidCrop.avi'])
        parfor nVid = 1 : dt.params.NProcessors
            vidsR = VideoReader(pathVids{nVid});
            vidsR.CurrentTime = 1/vidsR.FrameRate;
            vidsW = VideoWriter(pathVidsWrite{nVid}, 'Grayscale AVI');
            vidsW.FrameRate = vidsR.FrameRate;
            open(vidsW)
            numFrames = floor(vidsR.Duration*vidsR.FrameRate);
            for nf = 1 : numFrames
                if hasFrame(vidsR) && vidsR.CurrentTime < vidsR.Duration
                    try
                        frame = readFrame(vidsR, 'native');
                        writeVideo(vidsW,CropFrame(frame))
                    catch
                        disp(['Error occured in Vid' num2str(nVid)])
                        vidsR.CurrentTime = vidsR.CurrentTime + 1/vidsR.FrameRate;
                    end
                    if mod(nf,100) == 0
                        fprintf(1,'\t Processor #%2i, Image #%7i of %7i\n', nVid,nf,numFrames);
                    end
                end
            end
            close(vidsW)
        end
        delete(poolobj);
        disp(['DONE vid ' pathFlies(n).name 'VidCrop.avi'])
    end
end
disp('DONE')
