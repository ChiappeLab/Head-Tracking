%% Gui to test the head tracking parameters
function GuiTestTracking()
% add here the path to the video
v = VideoReader(' ');
% add here the path to the background image
bckImg = imread(' ');
% add here the path to the head template
tempPath = [pwd '\TempHead.tif'];


% define GUI parameters
f = figure('Visible', 'off', 'Position', [360, 300, 500, 320]);
bckImg = imgaussfilt(squeeze(bckImg(:,:,1)),16);
f.Units = 'normalized';
frameNo = 1;
v.CurrentTime = frameNo/v.FrameRate;
hplus = uicontrol('Style', 'pushbutton', 'String', '+', 'Position', [120, 290, 20, 20], ...
    'Callback', {@plusbutton_Callback});
hminus = uicontrol('Style', 'pushbutton', 'String', '-', 'Position', [150, 290, 20, 20],...
    'Callback', {@minusbutton_Callback});
txtbox = uicontrol(f,'Style','edit','String','FrameNo','Position',[50, 290, 50, 20], ...
    'Callback', {@txtbx});
slider = uicontrol(f,'Style','slider', 'Min',0,'Max',v.FrameRate*v.Duration,'Value',frameNo,...
    'Position',[180, 290, 150, 20], 'Callback',{@su});
hSave = uicontrol('Style', 'pushbutton', 'String', 'Save', 'Position', [420, 120, 20, 10],...
    'Callback', {@save_Callback});
hSave.Units = 'normalized';
p21 = axes('Units', 'pixels', 'Position', [50, 40, 140, 75]);
p22 = axes('Units', 'pixels', 'Position', [50, 120, 140, 75]);
p11 = axes('Units', 'pixels', 'Position', [50, 200, 140, 75]);

p12 = axes('Units', 'pixels', 'Position', [350, 180, 120, 100]);
% p13 = axes('Units', 'pixels', 'Position', [350, 120, 75, 50]);
p14 = axes('Units', 'pixels', 'Position', [350, 40, 120, 100]);

p32 = axes('Units', 'pixels', 'Position', [220, 180, 120, 100]);
p13 = axes('Units', 'pixels', 'Position', [350, 120, 75, 100]);
p34 = axes('Units', 'pixels', 'Position', [220, 40, 120, 100]);

currTemplateHead = zeros(101,81);
axes(p11);
axis off;
axes(p21);
axis off;
axes(p12);
axis off;
axes(p13);
axis off;
axes(p14);
axis off;
axes(p22);
axis off;
axes(p32);
axis off;
axes(p34);
axis off;
p11.Units = 'normalized';
p21.Units = 'normalized';
p12.Units = 'normalized';
p32.Units = 'normalized';
p34.Units = 'normalized';
p14.Units = 'normalized';
p22.Units = 'normalized';
txtbox.Units = 'normalized';
hplus.Units = 'normalized';
hminus.Units = 'normalized';
slider.Units = 'normalized';

f.Name = 'NavigateVideo';
movegui(f, 'center')
f.Visible = 'on';
colormap gray

    % move to next frame
    function plusbutton_Callback(source, eventdata)
        if frameNo <= v.Duration*v.FrameRate
            frameNo = frameNo + 3;
            updateAxes(frameNo);
        end
    end
    % move to previous frame
    function minusbutton_Callback(source, eventdata)
        if frameNo >= 2
            frameNo = frameNo - 3;
            updateAxes(frameNo);
        end
    end
    % funtion to write down a frame number
    function txtbx(hObject, eventdata, handles)
        input = str2double(get(hObject,'String'));
        if isnan(input)
            errordlg('You must enter a numeric value','Invalid Input','modal')
            uicontrol(hObject)
            return
        else
            frameNo = input;
            updateAxes(input);
        end
    end
    function su(h,event)
        val = get(h,'Value');
        frameNo=floor(val);
        updateAxes(frameNo);
    end
    function save_Callback(source, eventdata)
        imwrite(currTemplateHead,tempPath);
    end
    % update and track the head in the new frame
    function updateAxes(fN)
        % load frame
        txtbox.String = num2str(fN);
        v.CurrentTime = fN/v.FrameRate;
        frame = readFrame(v);
        FRaw = frame(:,:,1);
        % track body position and rotation
        FRawSmooth = imgaussfilt(FRaw,16);
        [bckImg] = AdjustBackground(bckImg,FRawSmooth);
        [alignedImageBS, ~,~,~,img] = TrackBody(FRaw,FRawSmooth,bckImg);
        % segment head 
        [SegHead1, FBSHead1] = SegmentHead(alignedImageBS);
        [SegHead2, FBSHead2] = SegmentHead(imrotate(alignedImageBS,180));
        
        % Plot multiple steps
        axes(p11)
        cla
        imagesc(FRaw)
        set(gca,'Ydir','Normal')
        axis off
        caxis([0 255])
        
        axes(p21)
        cla
        imagesc(img)
        set(gca,'Ydir','Normal')
        axis off
        
        axes(p22)
        cla
        imagesc(alignedImageBS)
        hold on
        plot([512 512], [0 544], 'g', 'linewidth', 1)
        plot([0 1024], [272 272], 'g', 'linewidth', 1)
        set(gca,'Ydir','Normal')
        axis off
        
        if exist(tempPath, 'file') ~= 0
            temp = imread(tempPath);
            % track head position and rotation
            [Itemp] = ResizeTemplate(temp, SegHead1);
            [~, ~, ~, thetaTemp, ~] = AlignHeadImage(Itemp, Itemp, 0, Itemp);
            [alignedImage1, X1, Y1, theta1, errors1] = AlignHeadImage(SegHead1, Itemp, 0, SegHead1);
            axes(p14)
            cla
            imagesc(alignedImage1)
            hold on
            plot([50 50], [0 81], 'g', 'linewidth', 1)
            plot([0 101], [40 40], 'g', 'linewidth', 1)
            set(gca,'Ydir','Normal')
            axis off
            title(['X: ' num2str(X1) ' Y: ' num2str(Y1) ' Th: ' num2str(theta1-thetaTemp) ' Er: ' num2str(errors1(3))])
            axes(p34)
            cla
            imagesc(FBSHead1)
            hold on
            plot([50 50], [0 81], 'g', 'linewidth', 1)
            plot([0 101], [40 40], 'g', 'linewidth', 1)
            set(gca,'Ydir','Normal')
            axis off
            
            % rotate image 180 and track again the position and orientation
            [Itemp] = ResizeTemplate(temp, SegHead2);
            [~, ~, ~, thetaTemp, ~] = AlignHeadImage(Itemp, Itemp, 0, Itemp);
            [alignedImage2, X2, Y2, theta2, errors2] = AlignHeadImage(SegHead2, Itemp, 0, SegHead2);
            axes(p12)
            cla
            imagesc(alignedImage2)
            hold on
            plot([50 50], [0 81], 'g', 'linewidth', 1)
            plot([0 101], [40 40], 'g', 'linewidth', 1)
            set(gca,'Ydir','Normal')
            axis off
            title(['X: ' num2str(X2) ' Y: ' num2str(Y2) ' Th: ' num2str(theta2) ' Er: ' num2str(errors2(3))])
            
            axes(p32)
            cla
            imagesc(FBSHead2)
            hold on
            plot([50 50], [0 81], 'g', 'linewidth', 1)
            plot([0 101], [40 40], 'g', 'linewidth', 1)
            set(gca,'Ydir','Normal')
            axis off
            
        end
    end
end