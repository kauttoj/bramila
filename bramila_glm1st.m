function bramila_glm1st(file,outputdir)

HOME = pwd;
DELETE_TEMP_FILES = 1; % only useful if splitting
NEED_TO_SPLIT = 0; % 1 for spm8

% load cfg and unpack parameters
load(file,'cfg');

TR = cfg.TR;
sesses = cfg.sessions;
hpf = cfg.hpf;
incmoves = cfg.incmoves;
inputfile = cfg.inputfile;
motionfile = cfg.motionfile;
cnames = cfg.cnames;
regressor_unit = cfg.regressor_unit;
onsets = cfg.onsets;
durations = cfg.durations;

if ~isfield(cfg,'AR'), cfg.AR = 'none'; end
AR = cfg.AR;

% where would analysis result go
%outputdir = fullfile(dataroot,subject,outdirname);
if ~exist(outputdir,'dir')
    mkdir(outputdir);
end
%number of blocks
nsess = cfg.sessions;
%condition names
ncond = length(cnames);
% folder where the fun happens
for sess = 1:nsess
    
    [inputfile_path,inputfile1,ext] = fileparts(cfg.inputfile{sess});    
    
    inputfile = [inputfile1,ext];    
%     %% Split 4D volume into 3D volumes. When file is larger than 2.1gb, you have to split it
%     % assuming sessdata is folder with preprocessed data for given run/session
%     % assuming inputfile is epi.nii
    ffiles = [];

    if NEED_TO_SPLIT               
        fprintf('Splitting 4D file... ')
        
        tempfolder = [inputfile_path,filesep,inputfile1,'_SPLIT'];        
        do_split = 1;
        if ~exist(tempfolder,'dir')
           mkdir(tempfolder); 
        else
            d = dir([tempfolder,filesep,'*.nii']);
            if ~isempty(d)
                do_split = 0;
                warning('Temp split folder not empty (%i files), skipping split operation\n',length(d));
            end
        end
        assert(exist([inputfile_path,filesep,inputfile],'file')>0)
        if do_split
            spm_file_split([inputfile_path,filesep,inputfile],tempfolder);
            fprintf('done!\n')
        end
                
        files = spm_select('List',tempfolder,'.nii$');
        for f = 1:length(files)
            ffiles{f,1} = [fullfile(tempfolder,files(f,:)),',1'];
        end                
    else
        [ffiles,~] = spm_select('ExtFPList',inputfile_path,inputfile,Inf);
    end
    
    %% List files

%     % Throw them into the batch
%     matlabbatch{1}.spm.stats.fmri_spec.sess(sess).scans = ffiles;
    %% SPM12 seems to work just fine
    %    
    assert(~isempty(ffiles))
    % Throw them into the batch
    matlabbatch{1}.spm.stats.fmri_spec.sess(sess).scans = cellstr(ffiles);        
    %% Regressors
    % Create and throw into the batch
    for c = 1:ncond
        matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(c).name = cnames{c};
        matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(c).onset = onsets{sess}{c};
        matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(c).duration = durations{sess}{c};
        % no temporal or parametric modulations here
        matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(c).tmod = 0;
        if cfg.pmod == 1
            for p = 1:length(cfg.pmodname)
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(c).pmod(p).name = cfg.pmodname{p};
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(c).pmod(p).param = cfg.pmodparam{sess}{c}{p};
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(c).pmod(p).poly = 1;
            end
        end
    end
    %% Nuisance
    matlabbatch{1}.spm.stats.fmri_spec.sess(sess).multi = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(sess).regress = struct('name', {}, 'val', {});
    if incmoves==1
        R = load([sessdata '/' motionfile]);
        if length(R) ~= length(ffiles)
            disp('WARNING: the length of motion parameters is not equal to length of files, need to trim')
        end
        save([sessdata '/' motionfile '.mat'],'R');
        matlabbatch{1}.spm.stats.fmri_spec.sess(sess).multi_reg = {[sessdata '/' motionfile '.mat']};        
    else
        matlabbatch{1}.spm.stats.fmri_spec.sess(sess).multi_reg = {''};
    end
    
    %% High-pass filter
    matlabbatch{1}.spm.stats.fmri_spec.sess(sess).hpf = hpf;
end
%% Put together the other parts of batch
% where would results be
matlabbatch{1}.spm.stats.fmri_spec.dir = {outputdir};
% seconds or scans
matlabbatch{1}.spm.stats.fmri_spec.timing.units = regressor_unit;
% TR
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
% microtiming (ignore)
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;
% factorial model (ignore)
matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
% derivatives of hrf 
matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.25;
matlabbatch{1}.spm.stats.fmri_spec.mask = {[cfg.mask,',1']};
matlabbatch{1}.spm.stats.fmri_spec.cvi = AR;
%% Model estimation barch
matlabbatch{2}.spm.stats.fmri_est.spmmat = {[outputdir,filesep,'SPM.mat']};
% Classical or Bayesian? Dunno...
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
%% Contrast manager (can be ignored in future, if you want to understand it better)
if ~isempty(cfg.predefined_contrast)
    % If we defined contrasts in advance
    for cond = 1:length(cfg.predefined_contrast)
        contrst{cond} = cfg.predefined_contrast{cond};
        contrstname{cond} = cfg.predefined_contrast_name{cond};        
    end
else
    if ncond > 1
        contrst = cell(ncond*2,1);
        contrstname = contrst;
        % main effect is easy to manage
        for cond = 1:ncond
            % build the base of the contrast    
            contrst{cond} = zeros(1,ncond);
            contrst{cond}(cond) = 1;
            contrstname{cond} = [cnames{cond} ' Main Effect'];
        end
        % contrast (one vs all) is more sophisticated
        % cond + ncond to not overwrite anything
        for cond = 1:ncond
            % build the base of the contrast
            consbase = ones(1,ncond);
            consbase = consbase*-1;
            consbase(cond) = ncond - 1;        
            contrst{cond+ncond} = consbase;
            contrstname{cond+ncond} = [cnames{cond} ' vs All'];
        end
    elseif ncond == 1
        contrst = cell(1,1);
        contrstname = contrst;
        % main effect is easy to manage
        contrst{1} = 1;
        contrstname{1} = [cnames{1} ' Main Effect'];
    else
        disp('What is wrong with your cnames?')
    end
end
matlabbatch{3}.spm.stats.con.spmmat = {[outputdir '/SPM.mat']};
matlabbatch{3}.spm.stats.con.delete = 0;
for ct = 1:length(contrst)
    if size(contrst{ct},1)==1     
        matlabbatch{3}.spm.stats.con.consess{ct}.tcon.name = contrstname{ct};
        matlabbatch{3}.spm.stats.con.consess{ct}.tcon.sessrep = 'replsc'; % replicate and scale, only replicate 'repl';        
        matlabbatch{3}.spm.stats.con.consess{ct}.tcon.convec = contrst{ct};
    else
        matlabbatch{3}.spm.stats.con.consess{ct}.fcon.name = contrstname{ct};
        matlabbatch{3}.spm.stats.con.consess{ct}.fcon.weights = contrst{ct};
        matlabbatch{3}.spm.stats.con.consess{ct}.fcon.sessrep = 'replsc'; % replicate and scale, only replicate 'repl';        
    end
end
spm_jobman('initcfg');

save([outputdir,filesep,'batchfile.mat'],'matlabbatch')

spm_jobman('run',matlabbatch);

if NEED_TO_SPLIT*DELETE_TEMP_FILES
    fprintf('Deleting temp files and folders... ');
    cd(tempfolder);
    d=dir('*.nii');
    for i=1:length(d)
        delete(d(i).name);
    end
    cd(HOME);
    rmdir(tempfolder);
    fprintf('%i *.nii files deleted\n',length(d));    
end


