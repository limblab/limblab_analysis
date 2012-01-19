function batch_handControl_decoderPerformance

originalPath=pwd;

% this script operates on a folder that contains 1 or more .mat
% files containing FP and position data
BatchList={...
    'Chewie_Spike_LFP_09022011001',...
    'Chewie_Spike_LFP_09022011004',...
    'Chewie_Spike_LFP_09022011007',...
    'Chewie_Spike_LFP_09062011001',...
    'Chewie_Spike_LFP_09062011005',...
    'Chewie_Spike_LFP_09072011001',...
    'Chewie_Spike_LFP_09072011006',...
    'Chewie_Spike_LFP_09082011001',...
    'Chewie_Spike_LFP_09082011004',...
    'Chewie_Spike_LFP_09082011007',...
    'Chewie_Spike_LFP_09092011001',...
    'Chewie_Spike_LFP_09092011004',...
    'Chewie_Spike_LFP_09092011007',...
    'Chewie_Spike_LFP_09122011002',...
    'Chewie_Spike_LFP_09122011005',...
    'Chewie_Spike_LFP_09192011001',...
    'Chewie_Spike_LFP_09192011003',...
    'Chewie_Spike_LFP_09232011009.mat',...
    'Chewie_Spike_LFP_09262011002',...
    'Chewie_Spike_LFP_09262011003',...
    'Chewie_Spike_LFP_10032011001',...
    'Chewie_Spike_LFP_10032011002',...
    'Chewie_Spike_LFP_10102011001',...
    'Chewie_Spike_LFP_10102011002',...
    'Chewie_Spike_LFP_10142011001',...
    'Chewie_Spike_LFP_10172011003',...
    'Chewie_Spike_LFP_10172011004',...
    'Chewie_Spike_LFP_10262011001',...
    'Chewie_Spike_LFP_10312011008',...
    'Chewie_Spike_LFP_11302011001',...
    'Chewie_Spike_LFP_12012011001',...
    'Chewie_Spike_LFP_12022011001',...
    'Chewie_Spike_LFP_12062011002',...
    'Chewie_Spike_LFP_12072011001',...
    'Chewie_Spike_LFP_12082011001',...
    'Chewie_Spike_LFP_12092011001',...
    'Chewie_Spike_LFP_12122011001',...
    'Chewie_Spike_LFP_12132011001',...
    'Chewie_Spike_LFP_12142011002',...
    'Chewie_Spike_LFP_12152011001',...
    'Chewie_Spike_LFP_12192011001',...
    'Chewie_Spike_LFP_12202011001',...
    'Chewie_Spike_LFP_12212011001',...
    'Chewie_Spike_LFP_12222011005',...
    'Chewie_Spike_LFP_12222011008',...
    'Chewie_Spike_LFP_12272011001',...
    'Chewie_Spike_LFP_12272011004',...
    'Chewie_Spike_LFP_12282011001',...
    'Chewie_Spike_LFP_12282011005',...
    'Chewie_Spike_LFP_12292011001',...
    'Chewie_Spike_LFP_12292011005',...
    'Chewie_Spike_LFP_01032012001',...
    'Chewie_Spike_LFP_01032012005',...
    'Chewie_Spike_LFP_01042012001',...
    'Chewie_Spike_LFP_01042012005',...
    'Chewie_Spike_LFP_01052012001',...
    'Chewie_Spike_LFP_01052012006',...
    'Chewie_Spike_LFP_01062012001',...
    'Chewie_Spike_LFP_01062012004',...
    'Chewie_Spike_LFP_01062012011',...
    'Chewie_Spike_LFP_01092012001',...
    'Chewie_Spike_LFP_01092012005',...
    'Chewie_Spike_LFP_01122012009',...
    'Chewie_Spike_LFP_01162012002',...
    'Chewie_Spike_LFP_01162012006',...
    'Chewie_Spike_LFP_01172012006',...
    'Chewie_Spike_LFP_01182012001',...
        'Mini_Spike_LFPL_107',...
    'Mini_Spike_LFPL_111',...
    'Mini_Spike_LFPL_112',...
    'Mini_Spike_LFPL_116',...
    'Mini_Spike_LFPL_119',...
    'Mini_Spike_LFPL_124',...
    'Mini_Spike_LFPL_130',...
    'Mini_Spike_LFPL_138',...
    'Mini_Spike_LFPL_139',...
    'Mini_Spike_LFPL_140',...
    'Mini_Spike_LFPL_141',...
    'Mini_Spike_LFPL_142',...
    'Mini_Spike_LFPL_145',...
    'Mini_Spike_LFPL_146',...
    'Mini_Spike_LFPL_149',...
    'Mini_Spike_LFPL_152',...
    'Mini_Spike_LFPL_153',...
    'Mini_Spike_LFPL_156',...
    'Mini_Spike_LFPL_158',...
    'Mini_Spike_LFPL_163',...
    'Mini_Spike_LFPL_164',...
    'Mini_Spike_LFPL_167',...
    'Mini_Spike_LFPL_170',...
    'Mini_Spike_LFPL_171',...
    'Mini_Spike_LFPL_175',...
    'Mini_Spike_LFPL_193',...
    'Mini_Spike_LFPL_197',...
    'Mini_Spike_LFPL_226',...
    'Mini_Spike_LFPL_227',...
    'Mini_Spike_LFPL_260',...
    'Mini_Spike_LFPL_261',...
    'Mini_Spike_LFPL_294',...
    'Mini_Spike_LFPL_295',...
    'Mini_Spike_LFPL_296',...
    'Mini_Spike_LFPL_297',...
    'Mini_Spike_LFPL_322',...
    'Mini_Spike_LFPL_323',...
    'Mini_Spike_LFPL_352',...
    'Mini_Spike_LFPL_362',...
    'Mini_Spike_LFPL_	363',...
    'Mini_Spike_LFPL_	403',...
    'Mini_Spike_LFPL_	505',...
    'Mini_Spike_LFPL_	514',...
    'Mini_Spike_LFPL_	521',...
    'Mini_Spike_LFPL_	528',...
    'Mini_Spike_LFPL_	537',...
    'Mini_Spike_LFPL_	544',...
    'Mini_Spike_LFPL_	551',...
    'Mini_Spike_LFPL_	561',...
    'Mini_Spike_LFPL_	568',...
    'Mini_Spike_LFPL_	575',...
    'Mini_Spike_LFPL_	581',...
    'Mini_Spike_LFPL_	591',...
    'Mini_Spike_LFPL_	628',...
    'Mini_Spike_LFPL_	632',...
    'Mini_Spike_LFPL_	637',...
    'Mini_Spike_LFPL_	639',...
    'Mini_Spike_LFPL_	642',...
    'Mini_Spike_LFPL_	647',...
    'Mini_Spike_LFPL_	648',...
    'Mini_Spike_LFPL_	651',...
    'Mini_Spike_LFPL_	689'};
    
for n=1:length(BatchList)
    BatchList{n}=regexprep(BatchList{n},'\t',''); 

    try
        VAFstruct(n)=handControl_decoderPerformance(BatchList{n});
    end
    close
    cd(originalPath)
    save(fullfile(PathName,'VAFstruct.mat'),'VAFstruct')
    assignin('base','VAFstruct',VAFstruct)
end


