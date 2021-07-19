clear
clc
pathb = 'C:\Users\tomas\Dropbox (Sensorimotor)\ChiappeLabNew\DATA\TOMÁS\Free Walking VR\Data\Optomotor 1D 10D\';
flies = dir(pathb);
flies = flies(3:end);
for n = 1 : length(flies)
    close all
    tots = 0;
    % load the low resolution data file
    path = [pathb flies(n).name '\'];
    dtA = load([path 'DataLowRes.mat']);
    seq = dtA.Flies.Seq;
    dt = dtA.Flies.Data;
    disp(path)
    % load the head tracking file
    if exist([path 'AlignCropOutput.mat'], 'file') == 2
        bdt = load([path 'AlignCropOutput.mat']);
        Theta = [];
        Thetah = [];
        Errh = [];
        % concatenate data from the tracking in different video files using ordered video indices 
        indsCat = [1 2 3 4 5 6 7 8 9];
        for i = 1 : length(bdt.Theta)
            if ~isempty(bdt.Theta{indsCat(i)}) && length(bdt.Theta{indsCat(i)}) > 1
                Theta = vertcat(Theta, bdt.Theta{indsCat(i)}(1:end-1),bdt.Theta{indsCat(i)}(end-1));
                Thetah = vertcat(Thetah, bdt.Thetah{indsCat(i)}(1:end-1), bdt.Thetah{indsCat(i)}(end-1));
                Errh = vertcat(Errh, bdt.Errh{indsCat(i)}(1:end-1), bdt.Errh{indsCat(i)}(end-1));
            end
        end
        Thetah = mod(Thetah + 180, 360)-180;
        Vr = diff(Theta);
        inds = find(abs(Vr)>45);
        while ~isempty(inds)
            Theta((inds(1)+1):end) = Theta((inds(1)+1):end) - sign(Vr(inds(1)))*90;
            Vr = diff(Theta);
            inds = find(abs(Vr)>45);
        end
        Theta = smooth(Theta, 10/length(Theta), 'lowess');
        Vr = diff(Theta)*120;
        Vr = vertcat(Vr, Vr(end));
        Vrb = -Vr;
        Thetah = smooth(Thetah, 10/length(Thetah), 'lowess');
        Hangb = -Thetah;
        % clear the data associated with large tracking errors
        vect = zeros(length(Errh), 1);
        err2 = Errh;
        err2(err2>1) = nan;
        errthr = nanmean(err2) + 2*nanstd(err2);
        inds = find(Errh > errthr | abs(Hangb)>20);
        vect(inds) = 1;
        [Bts, ~] = Vec2Bout(vect, 0, 10, 4);
        for j = 1 : length(Bts)
            Vrb(Bts{j}) = nan;
            Hangb(Bts{j}) = nan;
        end

        dtA.Flies.HARaw = -Hangb;
        dtA.Flies.VrHR = -Vrb;
        dtA.Flies.ErrTrk = Errh;
        
        % add head angle informatio to the different trials during the
        % experiment
        for i = 1 : length(dtA.Flies.Data)
            enVal = min(length(Errh), dtA.Flies.Data{i}.FramesC2(end));
            vds = dtA.Flies.Data{i}.FramesC2(dtA.Flies.Data{i}.FramesC2<enVal);
            dtA.Flies.Data{i}.HangDS = dtA.Flies.HARaw(vds)- nanmean(dtA.Flies.HARaw(vds));%-2.188;
            dtA.Flies.Data{i}.VrHRDS = dtA.Flies.VrHR(vds);
            dtA.Flies.Data{i}.ErrTrkHRDS = dtA.Flies.ErrTrk(vds);
            dtA.Flies.Data{i}.Hang = dtA.Flies.HARaw(dtA.Flies.Data{i}.FramesC2(1):enVal);
            dtA.Flies.Data{i}.VrHR = dtA.Flies.VrHR(dtA.Flies.Data{i}.FramesC2(1):enVal);
            dtA.Flies.Data{i}.ErrTrkHR = dtA.Flies.ErrTrk(dtA.Flies.Data{i}.FramesC2(1):enVal);
            Fly = dtA.Flies;
            Fly.Seq = seq;
        end
        disp(num2str(100*tots./(24*3600)))
        save([path 'DataLowAndHighRes.mat'], 'Fly')
    end
end
