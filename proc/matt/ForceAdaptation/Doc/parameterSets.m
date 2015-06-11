function params = parameterSets(params,paramSetName)
% this is where I can define preset parameters for different names of
% paramter sets

setParamValues(params,'paramSetName',paramSetName);

switch lower(paramSetName)
    case 'baseline' % get baseline activity
        params = setParamValues(params,'tuningCoordinates','movement', ...
            'tuningMethods',{'regression'},...
            'tuningPeriods',{'baseline'},...
            'numberBootIterations',10,...
            'classifierBlocks',[1,4,7], ...
            'blocks', {[0,1],[0 0.33 0.66 1],[0 0.33 0.66 1]}, ...
            'useTasks',{'CO','RT','FF','VR'});
    case 'planning' % normal settings for target direction
        params = setParamValues(params,'tuningCoordinates','target', ...
            'tuningMethods',{'regression'},...
            'tuningPeriods',{'afton','befgo','aftgo'},...
            'classifierBlocks',[1,4,7], ...
            'blocks', {[0,1],[0 0.33 0.66 1],[0 0.33 0.66 1]}, ...
            'useTasks',{'CO','FF','VR'}, ...
            'm1_latency',0, ...
            'pmd_latency',0, ...
            'blocks',{[0 1],[0.33 1],[0.33 1]}, ...
            'classifierBlocks',[1 2 3]);
    case 'movement' % normal settings for movement direction
        params = setParamValues(params,'tuningCoordinates','movement', ...
            'tuningMethods',{'regression'},...
            'tuningPeriods',{'onpeak'},...
            'classifierBlocks',[1,4,7], ...
            'blocks', {[0,1],[0 0.33 0.66 1],[0 0.33 0.66 1]}, ...
            'useTasks',{'CO','RT','FF','VR'});
    case 'target' % normal settings for target direction
        params = setParamValues(params,'tuningCoordinates','target', ...
            'tuningMethods',{'regression'},...
            'tuningPeriods',{'full'},...
            'classifierBlocks',[1,4,7], ...
            'blocks', {[0,1],[0 0.33 0.66 1],[0 0.33 0.66 1]}, ...
            'useTasks',{'CO','RT','FF','VR'});
    case 'movetime' % using different time points over duration of CO movement
        % need some preprocessing
        divideTime = [0.3, 0.1];
        numBlocks = floor(( 1 + divideTime(2) - divideTime(1) ) / divideTime(2));
        params = setParamValues(params,'tuningCoordinates','movement', ...
            'tuningMethods',{'regression'},...
            'tuningPeriods',{'time'},...
            'classifierBlocks',[(1:numBlocks)',(numBlocks+1:2*numBlocks)',(2*numBlocks+1:3*numBlocks)'], ...
            'blocks', {[0,1],[0.33 1],[0.33 1]}, ...
            'divideTime',divideTime, ...
            'useTasks',{'CO','FF','VR'});
    case 'movefine' % using finer temporal resolution on blocks of PD fits
        params = setParamValues(params,'tuningCoordinates','movement', ...
            'tuningMethods',{'regression'},...
            'tuningPeriods',{'onpeak'},...
            'classifierBlocks',[ones(10,1),(2:11)',repmat(12,10,1)], ...
            'blocks', {[0,1],[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1],[0.33 1]}, ...
            'useTasks',{'CO','RT','FF','VR'});
    case 'targtime'
        % need some preprocessing
        divideTime = [0.3, 0.05];
        numBlocks = floor(( 1 + divideTime(2) - divideTime(1) ) / divideTime(2));
        params = setParamValues(params,'tuningCoordinates','target', ...
            'tuningMethods',{'regression'},...
            'tuningPeriods',{'time'},...
            'classifierBlocks',[(1:numBlocks)',(numBlocks+1:2*numBlocks)',(2*numBlocks+1:3*numBlocks)'], ...
            'blocks', {[0,1],[0.33 1],[0.33 1]}, ...
            'divideTime',divideTime, ...
            'useTasks',{'CO','FF','VR'});
    case 'targfine'
        params = setParamValues(params,'tuningCoordinates','target', ...
            'tuningMethods',{'regression'},...
            'tuningPeriods',{'onpeak'},...
            'classifierBlocks',[ones(10,1),(2:11)',repmat(12,10,1)], ...
            'blocks', {[0,1],[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1],[0.33 1]}, ...
            'useTasks',{'CO','RT','FF','VR'});
    case 'glm'
        params = setParamValues(params,'tuningCoordinates','movement', ...
            'tuningMethods',{'glm'},...
            'tuningPeriods',{'file'},...
            'classifierBlocks',[1,4,7], ...
            'blocks', {[0,1],[0 0.33 0.66 1],[0 0.33 0.66 1]}, ...
            'useTasks',{'CO','RT','FF','VR'});
    case 'speedslow'
        params = setParamValues(params,'tuningCoordinates','movement', ...
            'tuningMethods',{'regression'},...
            'tuningPeriods',{'onpeak'}, ...
            'classifierBlocks',[1,2,3], ...
            'blocks', {[0,1],[0.33 1],[0.33 1]}, ...
            'useTasks',{'RT','FF'});
    case 'speedfast'
        params = setParamValues(params,'tuningCoordinates','movement', ...
            'tuningMethods',{'regression'},...
            'tuningPeriods',{'onpeak'},...
            'classifierBlocks',[1,2,3], ...
            'blocks', {[0,1],[0.33 1],[0.33 1]}, ...
            'useTasks',{'RT','FF'});
    otherwise
        error('Parameter Set Name not recognized. Add it to .../doc/parameterSets.m!');
end