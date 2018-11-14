function F = MaskBody(FBSHead)
FBSHead(:,1:10) = 0;
%% Get X head pos
hb = smooth(sum(FBSHead(:,1:floor(end/2)),2));
hr = smooth(sum(FBSHead(:,ceil(end/2):end),2));
[~,lcb,~,pb] = findpeaks(-hb);
pb(lcb>30|lcb<10) = [];
lcb(lcb>30|lcb<10) = [];
[~,ind] = min(hb(lcb));
lcb = lcb(ind);
pb = pb(ind);
if(isempty(lcb))
    lcb = 0;
    pb = 0;
end

[~,lcr,~,pr] = findpeaks(-hr);
pr(lcr>30|lcr<10) = [];
lcr(lcr>30|lcr<10) = [];
[~,ind] = min(hr(lcr));
lcr = lcr(ind);
pr = pr(ind);
if(isempty(lcr))
    lcr = 0;
    pr = 0;
end
if(pr+pb)==0
    xhead = 20;
    yhead = floor(size(FBSHead,2)/2)+3;
else
    xhead = round((lcr*pr+lcb*pb)/(pr+pb));
    yhead = floor(size(FBSHead,2)/2)+3;
end
mask = zeros(size(FBSHead));

for x = 1 : size(FBSHead,2);
    for y = 1 : size(FBSHead,1);
        if y > -0.0000075 * (x-yhead)^4 + xhead %%% 0.0075
            mask(y,x) = 1;
        end
        if y > xhead+20 + x
            mask(y,x) = 0;
        end
        if y > xhead+20 + (100-x)
            mask(y,x) = 0;
        end
        if y < xhead - 0.5*x
            mask(y,x) = 0;
        end
        if y < xhead - 0.5*(100-x)
            mask(y,x) = 0;
        end
    end
end
w = size(FBSHead,2);
aux = FBSHead(1:(xhead+37),:);
auxL = aux(:,1:floor(w/2));
valL = 1.0*mean(mean(auxL(auxL>5)));
auxL(auxL<valL) = 0;
aux(:,1:floor(w/2)) = auxL;

auxR = aux(:,floor(w/2):w);
valR = 1.0*mean(mean(auxR(auxR>5)));
auxR(auxR<valR) = 0;
aux(:,floor(w/2):w) = auxR;
FBSHead(1:(xhead+37),:) = aux;
F = immultiply(logical(mask),FBSHead);





end