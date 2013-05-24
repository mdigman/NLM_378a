function test_suite( algorithmHandle, config )
  % CRITICAL CONFIG CHECK
  % if not present write default
  testSuiteAddNoise = true;
  if any(strcmp(fields(config), 'testSuiteAddNoise'))
    testSuiteAddNoise = config.testSuiteAddNoise;
  end
  testSuiteUseAudioFiles = {};
  if any(strcmp(fields(config), 'testSuiteUseAudioFiles'))
    testSuiteUseAudioFiles = config.testSuiteUseAudioFiles;
  end
  testSuiteUseExternalAudio = false; %note: testSuiteUseExternalAudio MUST be present
  testSuiteExternalAudio = [];
  testSuiteExternalAudioFs = 44100;
  if any(strcmp(fields(config), 'testSuiteUseExternalAudio')) && ...
      any(strcmp(fields(config), 'testSuiteExternalAudio')) && ...
      any(strcmp(fields(config), 'testSuiteExternalAudioFs'))
    testSuiteUseExternalAudio = config.testSuiteUseExternalAudio;
    testSuiteExternalAudio = config.testSuiteExternalAudio;
    testSuiteExternalAudioFs = config.testSuiteExternalAudioFs;
  end


  % FILE SETUP
  % by default uses all images, change config.testSuiteUseImages to pick
  % individual files
  if isunix
    fileSepChar = '/';
    inDir = ['../../data/audio'];
    addpath('./matlab-ParforProgress2') % Add path for parallel progress tracking
  else
    fileSepChar = '\';
    inDir = ['..\..\data\audio'];
    addpath('.\matlab-ParforProgress2') % Add path for parallel progress tracking
  end

  if testSuiteUseExternalAudio
    nFiles = 1;
  elseif isunix
    if isempty(testSuiteUseAudioFiles)
      files = strsplit(ls(inDir),' '); %Put each name into cell array
      sFiles = size(files);
      nFiles = sFiles(2);
    else
      nFiles = numel(testSuiteUseAudioFiles);
      files = testSuiteUseAudioFiles;
    end
  else
    if isempty(testSuiteUseAudioFiles)
      files = ls(inDir);
      files = files(3:end,:);
      sFiles = size(files);
      nFiles = sFiles(1);
    else
      nFiles = numel(testSuiteUseAudioFiles);
      files = testSuiteUseAudioFiles;
    end
  end

  % EXTRACT NECESSARY CONFIG INFORMATION
  noiseSig = config.noiseSig; %standard deviation
  noiseMean = config.noiseMean;

  dateTime = datestr(now);
  dateTime = strrep(dateTime, ':', '');
  dateTime = strrep(dateTime, '-', '');
  dateTime = strrep(dateTime, ' ', '_');
  outDir = ['output',fileSepChar,'output_',dateTime];
  mkdir(outDir);

  if testSuiteUseExternalAudio
    wavwrite(testSuiteExternalAudio, testSuiteExternalAudioFs, [outDir,fileSepChar,'external_audio.wav']);
  else
    callSeq = dbstack();
    nCallSeq = numel( callSeq );
    runFile = callSeq( nCallSeq ).file;
    copyfile( runFile, [outDir,fileSepChar,runFile] );
  end


  % RECORD CONFIG FOR FUTURE REFERENCE
  configID = fopen([outDir,fileSepChar,'config.txt'], 'w');
  fieldNames = fields(config);
  for i=1:numel(fieldNames)
    fprintf( configID, '%s: ', fieldNames{i});
    allValues = config.(fieldNames{i});
    if ~strcmp(fieldNames{i}, 'testSuiteExternalAudio')
      for j=1:numel(allValues)
        if iscell(allValues(j))
          fprintf( configID, '%f, ', allValues{j});
        else
          fprintf( configID, '%f, ', allValues(j));
        end
      end
    end
    fprintf(configID, '\n');
  end
  fclose(configID);

  % OPEN FILES FOR WRITING
  logID = fopen([outDir,fileSepChar,'log.csv'], 'w');
  fprintf( logID, 'filename, runtime (sec), MSE, PSNR\n');

  % create functions for playing files
  function playOrigAudio(gcbo, eventData)
    sound(audio, fs);
  end

  function playNoisyAudio(gcbo, eventData)
    sound(noisyAudio, fs);
  end

  function playDenoisedAudio(gcbo, eventData)
    sound(deNoisedAudio, fs);
  end


  % PROCESS EACH FILE
  for i=1:nFiles
    if testSuiteUseExternalAudio
      audio = testSuiteExternalAudio;
      audioFile = 'external_audio.wav';
    else
      if ~isempty(testSuiteUseAudioFiles)
        audioFile = files{i};
      elseif isunix
        audioFile = files{i};
      else
        audioFile = strtrim( files(i,:) );
      end
      [audio, fs] = audioread( [inDir,fileSepChar,audioFile] );
    end

    % save fileName in config for parallel progress bar
    config.fileName = audioFile;

    % nDims is always 1. But check how many channels
    %       nDimsImg = ndims( img );
    %       if nDimsImg>2
    %           img = rgb2gray( img );
    %       end
    %
    wavwrite( audio, fs, [outDir,fileSepChar,'clean_',audioFile] );

    sAudio = size( audio );
    if testSuiteAddNoise
      noise = normrnd( noiseMean, noiseSig, sAudio(1), sAudio(2) );
      noisyAudio = audio + noise;
      % normalize if necessary
      if(max(max(abs(noisyAudio))) >= 1)
        noisyAudio = noisyAudio ./ max(max(abs(noisyAudio))) * 0.9999;
      end
    else
      noisyAudio = audio;
    end
    wavwrite( noisyAudio, fs, [outDir,fileSepChar,'noisy_',audioFile] );

    tic
    output = algorithmHandle(noisyAudio, config);
    runtime = toc;
    
    deNoisedAudio = output.deNoisedAudio;

    wavwrite( deNoisedAudio, fs, [outDir, fileSepChar, ...
      output.prefix, audioFile] );

    %% TODO: does the "click on the figure to play audio" work with multiple files?
    figure;
    
    subplot(411);
    myspectrogram(audio, fs, 2048);
    set(gca,'ButtonDownFcn', @playOrigAudio);
    set(get(gca,'Children'),'ButtonDownFcn', @playOrigAudio);
    title('spectrogram of original audio for -60 to 0dB. Click to play audio.');
    
    subplot(412);
    myspectrogram(noisyAudio, fs, 2048);
    set(gca,'ButtonDownFcn', @playNoisyAudio);
    set(get(gca,'Children'),'ButtonDownFcn', @playNoisyAudio);
    title('spectrogram of noisy audio for -60 to 0dB. Click to play audio.');
    
    subplot(413);
    myspectrogram(deNoisedAudio, fs, 2048);
    set(gca,'ButtonDownFcn', @playDenoisedAudio);
    set(get(gca,'Children'),'ButtonDownFcn', @playDenoisedAudio);
    title('spectrogram of denoised audio for -60 to 0dB. Click to play audio.');
    
    subplot(414);
    myspectrogram(noisyAudio - deNoisedAudio, fs, 2048);
    title('Difference between noisy and denoised audio');
    
    drawnow; % make sure it's displayed
    pause(0.05); % make sure it's displayed
    
    %sound(audio, fs);
    %sound(noisyAudio, fs);
    %sound(deNoisedAudio, fs);

    %% TODO: print spectrogram difference
    % don't forget to add myspectrogram function to matlab folder

    %calculate mse
    %mse = calculateMSE( audio, output.deNoisedAudio, output.borderSize );
    %psnr = calculatePSNR( audio, output.deNoisedAudio, output.borderSize );

    %fprintf( logID, '%s, %f, %f, %f, %f\n', audioFile, runtime, mse, psnr);

  end

  fclose(logID);
end
