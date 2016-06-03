function sortInd=sortCustomRegex(cellArrayToSort,orderedStrs)

% this is intended to take a cell array of strings and reorder it according
% to the scheme set forth in orderedStrs.  Example:
%
% cellArrayToSort={, ...
%     'ChewieSpikeLFP282sortedtik emgpred 150 feats lambda1 poly2.mat', ...
%     'ChewieSpikeLFP286sortedtik emgpred 150 feats lambda1 poly2.mat', ...
%     'Jaco_01-23-11_001sortedtik emgpred 150 feats lambda1 poly2.mat', ...
%     'Jaco_02-07-11_001sortedtik emgpred 150 feats lambda1 poly2.mat', ...
%     'MiniSpikeLFPL037sortedtik emgpred 150 feats lambda1 poly2.mat', ...
%     'MiniSpikeLFPL040sortedtik emgpred 150 feats lambda1 poly2.mat', ...
%     'MiniSpikeLFPL045sortedtik emgpred 150 feats lambda1 poly2.mat', ...
%     'MiniSpikeLFPL063sortedtik emgpred 150 feats lambda1 poly2.mat', ...
%     'Thor_11-3-10_mid_iso_002sortedtik emgpred 150 feats lambda1 poly2.mat', ...
%     'Thor_11-3-10_prone_iso_001sortedtik emgpred 150 feats lambda1 poly2.mat', ...
%	  }
% 	
% and 
% 	
% 	orderedStrs={'Chewie','Mini','Jaco','Thor'}
% 
% because we wanted proximal EMGs to be listed first.  Then,
% 	
% 	sortInd=[1     2     5     6     7     8     3     4     9    10]

% do it the dumb way until you think of a smarter way

sortInd=[];

for n=1:length(orderedStrs)
	hits{n}=find(cellfun(@isempty,regexp(cellArrayToSort,[orderedStrs{n}]))==0);
	if ~isempty(hits{n})
		sortInd=[sortInd, hits{n}];
	end
end