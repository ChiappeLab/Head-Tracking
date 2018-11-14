function ParallelAlignment(params)
poolobj = gcp('nocreate'); 
if isempty(poolobj)
    parpool(params.NProcessors)
end

X = cell(params.NProcessors, 1);
Y = cell(params.NProcessors, 1);
Theta = cell(params.NProcessors, 1);
Xh = cell(params.NProcessors, 1);
Yh = cell(params.NProcessors, 1);
Thetah = cell(params.NProcessors, 1);
Errh = cell(params.NProcessors, 1);

parfor i = 1:params.NProcessors
    try
        [X{i}, Y{i}, Theta{i}, Xh{i}, Yh{i}, Thetah{i}, Errh{i}] = AlignFrames(i, params);
    catch
       disp(['Problem in video ' num2str(i)])
       X{i}=[];
       Y{i}=[];
       Theta{i}=[];
       Xh{i}=[];
       Yh{i}=[]; 
       Thetah{i}=[];
       Errh{i} = []; 
    end
end
save([params.pathSave 'AlignOutput2.mat'], 'X', 'Y', 'Theta', 'Errh', 'Theta', 'Xh', 'Yh', 'Thetah', 'params')
delete(poolobj);
end