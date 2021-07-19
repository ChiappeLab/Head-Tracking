%% Head tracking via template matching - this code uses parallel processing toolbox
% addpath('General Functions')

clear
clc
pathFlies{1} = '';
pathFlies{2} = '';
params = GetParams();
for j = 1 : length(pathFlies)
    clc
    pathFly = pathFlies{j};
    disp([num2str(j) '  ' pathFly])
    % Get all videos in the directory 
    videos = dir([pathFly '*.avi']);
    params.pathSave = pathFly;
    % Path for a pre-existing image of the background
    params.pathVideos = cell(length(videos), 1);
    for i = 1 : length(videos)
        params.pathVideos{i} = [pathFly videos(i).name];
    end
    params.NProcessors = length(videos);
    poolobj = gcp('nocreate');
    delete(poolobj);
    ParallelAlignment(params)
end