
function run_deNoise2D_NLM( inDir )
  close all; clear;

  if nargin<1
    inDir = '..\..\data\images';
  end;

  noiseMean = 0;
  noiseSig = 0.05;
  
  files = ls(inDir);
  files = files(3:end,:);

  sFiles = size(files);
  nFiles = sFiles(1);

  dateTime = datestr(now);
  dateTime = strrep(dateTime, ':', '');
  dateTime = strrep(dateTime, '-', '');
  dateTime = strrep(dateTime, ' ', '_');
  outDir = ['output_',dateTime];
  %outDir = 'output';
  mkdir(outDir);

  logID = fopen([outDir,'\log.txt'], 'w');
  
  figure('name','Comparison');
  compFigH = gcf;
  
  for i=1:nFiles
    imgFile = strtrim( files(i,:) );
    img = imread( [inDir,'\',imgFile] );

    nDimsImg = ndims( img );
    if nDimsImg>2
      img = rgb2gray( img );
    end
    
    img = double( img )/255.;
    
    sImg = size( img );
    noise = normrnd( noiseMean, noiseSig, sImg(1), sImg(2) );
    noisyImg = img + noise;    
    %noisyImg = imnoise( img, 'gaussian' );
    imwrite( noisyImg, [outDir,'\noisy_',imgFile] );

    tic
    deNoisedImg = deNoise2D_NLM( noisyImg, noiseSig );
    runtime = toc;

    imwrite( deNoisedImg, [outDir,'\',imgFile] );
    fprintf( logID, '%s runtime (sec): %f\n', imgFile, runtime );
  end

end

