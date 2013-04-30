function test_suite( algorithmHandle, config )

  if isunix
    fileSepChar = '/';
    inDir = ['../../data/images'];
    files = strsplit(ls(inDir),' '); %Put each name into cell array
    sFiles = size(files);
    nFiles = sFiles(2);
  else
    fileSepChar = '\';
    inDir = ['..\..\data\images'];
    files = ls(inDir);
    files = files(3:end,:);
    sFiles = size(files);
    nFiles = sFiles(1);
  end

  noiseSig = config.noiseSig; %standard deviation
  noiseMean = config.noiseMean;

  dateTime = datestr(now);
  dateTime = strrep(dateTime, ':', '');
  dateTime = strrep(dateTime, '-', '');
  dateTime = strrep(dateTime, ' ', '_');
  outDir = ['output_',dateTime];
  mkdir(outDir);

  callSeq = dbstack();
  nCallSeq = numel( callSeq );
  runFile = callSeq( nCallSeq ).file;
  copyfile( runFile, [outDir,fileSepChar,runFile] );

  logID = fopen([outDir,fileSepChar,'log.csv'], 'w');
  fprintf( logID, 'filename, runtime (sec), MSE\n');

  for i=1:nFiles
    if isunix
      imgFile = files{i};
    else
      imgFile = strtrim( files(i,:) );
    end
    img = imread( [inDir,fileSepChar,imgFile] );

    nDimsImg = ndims( img );
    if nDimsImg>2
        img = rgb2gray( img );
    end

    img = double( img )/255.;

    sImg = size( img );
    noise = normrnd( noiseMean, noiseSig, sImg(1), sImg(2) );
    noisyImg = img + noise;
    imwrite( noisyImg, [outDir,fileSepChar,'noisy_',imgFile] );

    tic
    output = algorithmHandle(noisyImg, config, img);
    runtime = toc;

    imwrite( output.deNoisedImg, [outDir, fileSepChar, ...
      output.prefix, imgFile] );

    magDiffImg = abs( img - output.deNoisedImg );
    imwrite( magDiffImg, [outDir, fileSepChar, output.prefix, ...
      '_diff_',imgFile] );
    
    fprintf( logID, '%s, %f, %f\n', imgFile, runtime, output.mse );
  end

  fclose(logID);

end
