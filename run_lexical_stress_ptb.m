function [expt] = run_lexical_stress_ptb(snum,dataPath,practicemode)

if nargin < 1 || isempty(snum), snum = 0; end
if nargin < 2 || isempty(dataPath), dataPath = cd; end
if nargin < 3 || isempty(practicemode), practicemode = 0; end

% check for pre-existing dir and output files
if ~exist(dataPath,'dir')
    mkdir(dataPath);
    fprintf('Created directory %s\n',dataPath);
end
bSave = savecheck(fullfile(dataPath,'expt.mat'));
if ~bSave, return; end

%% setup 
expt.name = 'lexical_stress';
expt.snum = snum;
expt.dataPath = dataPath;

% stimuli
expt.conds = {'SW_Noun' 'WS_Noun' 'SW_Verb' 'WS_Verb'};
% expt.words = {'bishop' 'boredom' 'chaos' 'custom' 'essence' ...
%     'abyss' 'advice' 'antique' 'belief' 'bequest' ...
%     'wonder' 'wander' 'vary' 'strengthen' 'stifle' ...
%     'retain' 'refuse' 'portray' 'offend' 'induce'};
% expt.words = {'custom' 'belief' 'wonder' 'retain'};

if practicemode == 1
    expt.words = {'custom' 'routine' 'motive' 'antique'};
    SW_Nouns = [1 3];
    WS_Nouns = [2 4];
    SW_Verbs = [];
    WS_Verbs = [];
    
else
    
    expt.words = {'bishop' 'boredom' 'chaos' 'entry' 'essence' ... % SW Nouns
        'fury' 'hatred' 'impulse' 'kingdom' 'maker' ...
        'mercy' 'pastor' 'nonsense' 'outcome' 'outset' ...
        'patience' 'scholar' 'folly' 'tenure' 'treaty' ... 
        'abyss' 'advice' 'affair' 'belief' ... % WS Nouns
        'bequest' 'buffoon' 'canal' 'cuisine' 'deceit' 'device' 'event' ...
        'expanse' 'extent' 'monsoon' 'prestige' 'receipt' ...
        'renown' 'response' 'revenge' 'typhoon' ...
        'alter' 'argue' 'bury' 'carry' 'frustrate' ... % SW Verbs
        'lessen' 'listen' 'manage' 'marry' 'peddle' ...
        'perish' 'prosper' 'punish' 'quicken' 'sever' ...
        'startle' 'stifle' 'strengthen' 'vacate' 'wander' ...
        'amuse' 'arise' 'attend' 'await' 'condemn' ... % WS Verbs
        'depict' 'describe' 'despise' 'destroy' 'erupt' ...
        'expose' 'forbid' 'ignore' 'improve' 'induce' ...
        'offend' 'portray' 'relax' 'retain' 'succeed'};


    % build up trial list
    % Set up the trial indices for each condition 
    SW_Nouns = 1:20;
    WS_Nouns = 21:40;
    SW_Verbs = 41:60;
    WS_Verbs = 61:80;
    
end

% Set up the condition indices for the trials
SW_N = ones(1,length(SW_Nouns)); 
WS_N = 2*ones(1,length(WS_Nouns));
SW_V = 3*ones(1,length(SW_Verbs));
WS_V = 4*ones(1,length(WS_Verbs));

% set condition ratio
condrat = [1 1 1 1];
wordbank = [repmat(SW_Nouns,[1,condrat(1)])  repmat(WS_Nouns,[1,condrat(2)]) repmat(SW_Verbs,[1,condrat(3)]) repmat(WS_Verbs,[1,condrat(4)])]; 
condbank = [repmat(SW_N,[1,condrat(1)])  repmat(WS_N,[1,condrat(2)]) repmat(SW_V,[1,condrat(3)]) repmat(WS_V,[1,condrat(4)])];  

nbreps = 1; % repetitions of wordbank per block
expt.nbtrials = length(wordbank)*nbreps; % number of trials per block
expt.nblocks = 1; % number of blocks
expt.ntrials = expt.nbtrials * expt.nblocks; % total number of trials in expt

expt.timing.stimdur = 1; % time stim is on screen, in seconds
expt.timing.interstimdur = 0.75; % minimum time between stims, in seconds                % maximum extra time between stims (jitter)

for b=1:expt.nblocks
    rp = ceil(randperm(expt.nbtrials)./(expt.nbtrials/length(wordbank)));
    allWords(1+expt.nbtrials*(b-1):expt.nbtrials*b) = wordbank(rp);
    allConds(1+expt.nbtrials*(b-1):expt.nbtrials*b) = condbank(rp);
end

expt.listWords = expt.words(allWords);
expt.listConds = expt.conds(allConds);
expt.allWords = allWords;
expt.allConds = allConds;
expt.inds = get_exptInds(expt,{'conds','words'});

% Make a path to the subject's folder
subjectPath = sprintf('%s/s%d',dataPath,snum);
            
% If a subject directory doesn't exist, make one
if ~exist(subjectPath,'dir')
    mkdir(subjectPath);
end

% save pre-log
save(fullfile(subjectPath,'expt.mat'),'expt');

%% run experiment
instr = sprintf('Please LISTEN, then REPEAT');
[expt,data] = listenspeak_expt(expt,[],instr,subjectPath);

%% output data
save(fullfile(subjectPath,'expt.mat'),'expt'); % resave with stimtimes
save(fullfile(subjectPath,'data.mat'),'data');
