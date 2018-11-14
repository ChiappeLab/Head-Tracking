function [locs2, w2, FWBout] = GetSpikes(Vr, thr, actState, Vf, maxvf,vft)
[pks,locs,w,p] = findpeaks(abs(Vr),'MinPeakDistance',0,'WidthReference','halfheight');
indx = find(pks > thr);
w = w(indx);
locs = locs(indx);
TSSub = zeros(size(actState));
maxvf = maxvf * max(Vf(actState==1));
locs2 = [];
w2 = [];
for k = 1 : length(locs)
    w(k) = w(k)+2;
    if((floor(locs(k) - 11) > 0) && (floor(locs(k) - w(k)) > 0) && ...
            (ceil(locs(k) + 4) < length(Vr)) && (floor(locs(k) + w(k)) < length(Vr)))
        vfb = Vf(floor(locs(k) - 11):ceil(locs(k) + 4));
        
        if min(vfb) < maxvf
            locs2 = vertcat(locs2,locs(k));
            w2 = vertcat(w2,w(k));
            TSSub((floor(locs(k) - w(k))):(ceil(locs(k) + w(k)))) = 1;
        end
    end
end
TSSub2 = zeros(size(Vr));
TSSub2(Vf > vft) = 1;
FWST=mod(actState+TSSub,2);
FWST=mod(FWST+TSSub2,3);
FWST(FWST ~= 2) = 0;
FWST(FWST == 2) = 1;
[FWBout] = TimeSeriesToBout(FWST, 10);
FWBout2 = FWBout;
meanVf = [];
aux = 1;
for j = 1 : length(FWBout2)
    meanVf = vertcat(meanVf, mean(Vf(FWBout2{j})));
    if mean(Vf(FWBout2{j})) >= maxvf
        FWBout{aux} = FWBout2{j};
        aux = aux + 1;
    end
end


end
