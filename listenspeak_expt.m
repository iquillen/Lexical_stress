function [expt,data,subjectPath] = listenspeak_expt(expt,fontsize,instr,subjectPath)
%LISTENSPEAK_EXPT  Template for listen-repetition experiment.
%   LISTENSPEAK(EXPT) runs a speech production experiment given the
%   parameters defined in EXPT (e.g., words, color of text, timing, etc.).
%   FONTSIZE sets the size of the displayed text.

if nargin < 2 || isempty(fontsize), fontsize = 250; end
if nargin < 3, instr = []; end

% psychtoolbox
AssertOpenGL; % Running on PTB-3? Abort otherwise.
while KbCheck; end; % Wait for release of all keys on keyboard

% audio
InitializePsychSound();   % initialize sound driver
paMode_playback = 1;    % audio playback
paMode_record = 2;      % audio capture
%paMode_simult = 3;      % simultaneous audio capture and playback
if IsWin
    latencyClass = 0;   % no low-latency mode, for now (need ASIO)
else
    latencyClass = 0;   % try low-latency mode
end
fs = 44100;             % sampling rate
nchannels = 2;          % stereo capture
bufsize = 10;           % 10-second buffer

%% experiment
try
    %% setup screen, display intro text
    % Choose display (highest dislay number is a good guess)
    screens=Screen('Screens');
    screenNumber=max(screens);
    win = Screen('OpenWindow', screenNumber);
    Screen('FillRect', win, [0 0 0]);
    Screen('TextFont', win, 'Arial');
    
    Screen('TextSize', win, 50);
    DrawFormattedText(win,'Please wait.','center','center',[255 255 255]);
    Screen('Flip',win);
    KbWait;
    Screen('Flip',win);
    
    %% display experiment text
    if ~isempty(instr)
        DrawFormattedText(win,instr,'center','center',[255 255 255]);
        Screen('Flip',win);
        WaitSecs(1);
        KbWait;
        Screen('Flip',win);
        WaitSecs(.5);
    end

%     DrawFormattedText(win,'Press any key to begin the experiment.','center','center',[255 255 255]);
%     Screen('Flip',win);
%     WaitSecs(1);
%     KbWait;
%     Screen('Flip',win);
    
    % display words
    
    % Set up vectors to hold recording and stimulus presentation times
    rectimes_speak = zeros(1,expt.ntrials);
    stimtimes_speak = zeros(1,expt.ntrials);
    rectimes_listen = zeros(1,expt.ntrials);
    stimtimes_listen = zeros(1,expt.ntrials);
   
    for b=1:expt.nblocks
        WaitSecs(1)
        Screen('TextSize', win, 50);
        DrawFormattedText(win,'Get ready to LISTEN.','center','center',[255 255 255]);
        Screen('Flip',win);
        KbWait;
        Screen('Flip',win);
        for w=1:expt.nbtrials
            %% LISTEN
            pahandle = PsychPortAudio('Open', [], paMode_playback, latencyClass, fs, nchannels);
            
            t = w+(b-1)*expt.nbtrials; % current trial number
            
            % put text in buffer
            Screen('TextSize', win, fontsize);
            txt2display = expt.words{expt.allWords(t)};
            DrawFormattedText(win,txt2display,'center','center',[255 255 255]);
            
            % Get into file with audio recordings
            audioPath = sprintf('%s/%s',expt.dataPath,'normalized_recordings');
            cd(audioPath)
            
            % Extract audio data
            filename = sprintf('%s.wav', expt.words{expt.allWords(t)}); % The audio file should match the word displayed
            [signalIn,fs] = audioread(filename);
            
            % put audio in buffer
            audiodata = [signalIn'; signalIn'];
            audiodata = [audiodata zeros(2,round(fs))]; %#ok<AGROW> % pad buffer with 1s of tacked-on zeros
            PsychPortAudio('FillBuffer', pahandle, audiodata);
            
            % start playback
            rectimes_listen(t) = PsychPortAudio('Start', pahandle, 0, 0, 1);
            
            % display text
            stimtimes_listen(t) = Screen('Flip',win);
            WaitSecs(expt.timing.stimdur);
            
            % stop playback
            PsychPortAudio('Stop', pahandle);
            
            % close audio device
            PsychPortAudio('Close', pahandle);
            
            %% REPEAT          
            pahandle = PsychPortAudio('Open', [], paMode_record, latencyClass, fs, nchannels);
            PsychPortAudio('GetAudioData', pahandle, bufsize);
            
%             WaitSecs(1);
%             Screen('TextSize', win, 50);
%             DrawFormattedText(win,'Get ready to REPEAT.','center','center',[255 255 255]);
%             Screen('Flip',win);
%             KbWait;
%             Screen('Flip',win);
            
            % put text in buffer 
            Screen('TextSize', win, 50);
            % txt2display = expt.words{expt.allWords(t)};
            txt2display = '+'; % display a cross
            DrawFormattedText(win,txt2display,'center','center',[255 255 255]);
            
            % start recording
            rectimes_speak(t) = PsychPortAudio('Start', pahandle, 0, 0, 1);
            
            % draw text to screen
            stimtimes_speak(t) = Screen('Flip',win);
            
            WaitSecs(expt.timing.stimdur);
            
            KbWait;
            
            % clear screen
            Screen('Flip',win);
            % WaitSecs(expt.timing.interstimdur);
            
            % stop recording; retrieve audio data
            PsychPortAudio('Stop', pahandle);
            audiodata = PsychPortAudio('GetAudioData', pahandle);
            
            % Get into the subject directory
            cd(subjectPath);
            
            % Save audio data
            data(t).signalIn = audiodata(1,:)';
            data(t).params.fs = fs;
            
            % Save audio data for the trial as .WAV file
            wavfile = fullfile(subjectPath,sprintf('%s%d_%d_%s.wav','s',expt.snum,t,expt.words{expt.allWords(t)}));
            audiowrite(wavfile,transpose(audiodata),fs);
                 
            % close audio device
            PsychPortAudio('Close', pahandle); 
            WaitSecs(1);
            
        end
        
        % at end of block
        % save partial data
        save(fullfile(subjectPath,'data.mat'),'data');
        
        % at end of block, display break or end-of-experiment text
        Screen('TextSize', win, 50);
        if b < expt.nblocks
            breaktext = sprintf('Time for a break!\n\n%d of %d trials done.\n\n\n\nPress the button to continue.',t,ntrials);
        else
            breaktext = 'Thank you!\n\n\n\nPlease wait.';
        end
        DrawFormattedText(win,breaktext,'center','center',[255 255 255]);
        Screen('Flip',win);
        if b < expt.nblocks
            KbWait;
        else
            KbWait;
        end
        Screen('Flip',win);
    end    
    
    %% end expt
    Screen('CloseAll');
    
catch
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end

% Add recording and stimulus times to experiment log
expt.rectimes_listen = rectimes_listen;
expt.stimtimes_listen = stimtimes_listen;
expt.rectimes_speak = rectimes_speak;
expt.stimtimes_speak = stimtimes_speak;
    
