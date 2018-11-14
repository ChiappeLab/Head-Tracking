function [Itemp] = ResizeTemplate(temp, img)
areaTemp = sum(sum(temp));
areaFrame = sum(sum(img));
ratio = 1-areaFrame/areaTemp;
pIncrease = floor(size(temp,1) * ratio);

if ratio < 1
    Itemp = zeros(size(temp,1) +pIncrease, size(temp,2));
    Itemp(1:size(temp,1), :) = temp;
    Itemp = imresize(Itemp, size(img));
    Itemp = uint8(Itemp);
else
    Itemp = temp;
end
Itemp = imfill(Itemp);
end