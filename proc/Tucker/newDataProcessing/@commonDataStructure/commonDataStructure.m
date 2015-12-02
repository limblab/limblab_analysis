classdef commonDataStructure < matlab.mixin.SetGet%handle
    properties (Access = public)%anybody can read/write/whatever to these
        kinFilterConfig
        emgFilterConfig
        lfpFilterConfig
        binConfig
    end
    properties (SetAccess = private)%anybody can read these, but only class methods can write to them
        meta=struct('cds_version',{0})
        enc
        pos
        vel
        acc
        force
        EMG
        LFP
        analog
        trials
        units
        words
        databursts
        aliasList
    end
    properties (Transient = true)
        %scratch space for user data. Not saved with the common_data_structure
        scratch
    end
    methods (Static = true)
        function cds=commonDataStructure(varargin)
            %cds=common_data_structure(str,varargin)
            %constructor function. 
            
            %% set meta field
                cds.meta.cds_version=0;
                cds.meta.cds_data_source='empty_cds';
                cds.meta.filename='unknown_source_file';
                cds.meta.duration=0;
                cds.meta.lab=-1;
                cds.meta.datetime=-1;
                cds.meta.task='Unknown';
                cds.meta.summary=[];
                cds.meta.knownProblems={};
                meta.processedWith={'function','date','computer name','user name','Git revision hash','operation_data'};
            %% filters
                cds.kinFilterConfig.poles=8;
                cds.kinFilterConfig.cutoff=25;
                cds.kinFilterConfig.SR=100;
                cds.EMGFilterConfig.poles=4;%a band pass butterworth has effectiveley twice the number of poles
                cds.EMGFilterConfig.cutoff=[10 500];
                cds.EMGFilterConfig.SR=2000;
                cds.LFPFilterConfig.poles=4;%a band pass butterworth has effectiveley twice the number of poles
                cds.LFPFilterConfig.cutoff=[3 500];
                cds.LFPFilterConfig.SR=2000;
            %% empty kinetics tables
                cds.enc=cell2table(cell(0,3),'VariableNames',{'t','th1','th2'});
                cds.pos=cell2table(cell(0,4),'VariableNames',{'t','x','y','good'});%uses cell2table since you can't natively assign an empty table
                cds.vel=cell2table(cell(0,4),'VariableNames',{'t','vx','vy','good'});%uses cell2table since you can't natively assign an empty table
                cds.acc=cell2table(cell(0,4),'VariableNames',{'t','ax','ay','good'});
                cds.force=cell2table(cell(0,4),'VariableNames',{'t','fx','fy','good'});
            %% empty emg table
                cds.EMG=cell2table(cell(0,2),'VariableNames',{'t','emg'});
            %% empty lfp table
                cds.LFP=cell2table(cell(0,2),'VariableNames',{'t','lfp'});
            %% empty analog field
                cds.analog=[];
            %% units
                cds.units=struct('chan',[],'ID',[],'array',[],'spikes',cell2table(cell(0,2),'VariableNames',{'ts','wave'}));
            %% empty table of trial data
                cds.trials=cell2table(cell(0,5),'VariableNames',{'trial_number','start_time','go_time','end_time','trial_result'});
            %% empty table of words
                cds.words=cell2table(cell(0,2),'VariableNames',{'ts','word'});
            %% empty table of databursts
                cds.databursts=cell2table(cell(0,2),'VariableNames',{'ts','word'});
            %% empty list of aliases to apply when loading analog data
                cds.aliasList=cell(0,2);
            %% scratch space
                cds.scratch=[];
        end
    end
    methods (Static = false)
        %the following are setter methods for the common_data_structure class, 
        function setField(cds,fieldName,obj)
            cds.(fieldName)=obj;
        end
        
        addProblem(cds,problem)
        addOperation(cds,operation)
        
    end
    methods (Static = false)
        %The following are methods for the common_data_structure class, but
        %are defined in alternate files. These files MUST be stored in the
        %@common_data_structure folder, and are only accessible through
        %instances of the class
        
        %data loading functions:
        bdf2cds(cds,bdf)
        NEVNSx2cds(cds,NEVNSx,varargin)
        sourceFile2cds(cds,folderPath,fileName,varargin)
        %
        [task,opts]=getTask(cds,task,opts)
        writeSessionSummary(cds)
        checkEMG60hz(cds)
        checkLFP60hz(cds)
        refilterEMG(cds)
        refilterLFP(cds)
        binned=bin_data(cds)
        %trial table functions
        getTrialTable(cds)
        getWFTaskTable(cds,times)
        getRWTaskTable(cds,times)
        getCOTaskTable(cds,times)
        getBDTaskTable(cds,times)
        getUNTTaskTable(cds,times)
        getRPTaskTable(cds,times)
        getDCOTaskTable(cds,times)
    end
end
        
