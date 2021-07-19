%% function to align the head image to the template head image
function [alignedImage, X2, Y2, theta, errors] = AlignHeadImage(frame, temp, prevAngle, frameO, th0)
if nargin < 6
    th0 = 0;
end
spacing = 1;
fractionalPixelAccuracy = 1;
N = 180/spacing;
errors = zeros(3,1);
% register the 2D fft of the frame into the template
s = size(temp);
if isempty(find(isnan(frame), 1)) || isempty(find(isinf(frame), 1))
    F1 = fft2(temp);
    F2 = fft2(frame);
    shifts = dftregistration(F1,F2,round(1/fractionalPixelAccuracy));
    X = shifts(4);
    Y = shifts(3);
else
    X = 0;
    Y = 0;
end
% transform the frame using the registration shifts
T = affine2d([1 0 0 ;0 1 0; X Y 1]);
frame = imwarp(frame, T,'OutputView', imref2d(s));
frameO = imwarp(frameO, T,'OutputView', imref2d(s));

if sum(sum(frame)) ~= 0
    % Rotational alignment
    thetas = linspace(0, 180-spacing, N);
    % Find fft of the Radon transform
    F1 = abs(fft(radon(frame, thetas)));
    F2 = abs(fft(radon(temp, thetas)));
    % Find the index of the correlation peak
    correlation = sum(fft2(F1) .* fft2(F2));
    peaks = real(ifft(correlation));
    peakIndex = find(peaks==max(peaks));
    if length(peakIndex) > 1
        peakIndex = peakIndex(1);
    end
    % Find rotation angle via quadratic interpolation
    if (peakIndex~=1) && (peakIndex ~= N)
        p=polyfit(thetas((peakIndex-1):(peakIndex+1)),peaks((peakIndex-1):(peakIndex+1)),2);
        theta = -.5*p(2)/p(1);
        errors(1) = polyval(p,theta);
    else
        if peakIndex == 1
            p = polyfit([thetas(end)-180,thetas(1),thetas(2)],peaks([N,1,2]),2);
            theta = -.5*p(2)/p(1);
            errors(1) = polyval(p,theta);
            if theta < 0
                theta = 180 + theta;
            end
        else
            p = polyfit([thetas(end-1),thetas(end),180+thetas(1)],peaks([N-1,N,1]),2);
            theta = -.5*p(2)/p(1);
            errors(1) = polyval(p,theta);
            if theta >= 180
                theta = theta - 180;
            end
        end
    end
    
    % Check to see if rotation angle is in the correct direction
    rA = theta*pi/180;
    prevAngle = prevAngle*pi/180;
    test = dot([cos(rA),sin(rA)],[cos(prevAngle),sin(prevAngle)]);
    if test < 0
        theta = mod(theta-180,360);
    end
    theta = mod(theta,360);
%     theta = CorrectOrientation(theta, prevAngle);
else
    theta = prevAngle;
end
toRotate = mod(-theta-th0,360);


% Rotate Image & Crop to original Size
if  isempty(find(isnan(frame))) && isempty(find(isinf(frame))) &&  sum(sum(frame)) > 0
    rotatedImage = imrotate(frame,toRotate, 'crop');
    F1 = fft2(temp);
    F2 = fft2(rotatedImage);
%     F2 = fft2(frame);
    shifts = dftregistration(F1,F2,round(1/fractionalPixelAccuracy));
    X2 = shifts(4);
    Y2 = shifts(3);
    errors(2) = shifts(1);
    rotatedImage2 = imrotate(frameO,toRotate,'crop');
else
    X2 = 0;
    Y2 = 0;
    rotatedImage2 = imrotate(frameO,toRotate,'crop');
    rotatedImage = imrotate(frame,toRotate, 'crop');
end
T = affine2d([1 0 0 ;0 1 0; X2 Y2 1]);
X2 = X2+X;
Y2 = Y2+Y;
alignedImageTemp = imwarp(rotatedImage, T,'OutputView', imref2d(s));
errors(3) = sum(sum(abs(double(temp)-double(alignedImageTemp))))/sum(sum(abs(double(alignedImageTemp))));
alignedImage = imwarp(rotatedImage2, T,'OutputView', imref2d(s));

end