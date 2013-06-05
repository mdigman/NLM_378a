
function runStuff

  algorithms = { @deNoise2D_NLM, @deNoise2D_NLM_modPrior, ...
    @deNoise2D_NLM_plus, @deNoise2D_NLM_modPrior_plus, ...
    @deNoise2D_NLM_Euc, @deNoise2D_NLM_Euc_modPrior, ...
    @deNoise2D_NLM_euc_plus, @deNoise2D_NLM_euc_modPrior_plus, ...
    @deNoise2D_NLM_GW, @deNoise2D_NLM_GW_modPrior, ...
    @deNoise2D_NLM_GW_plus, @deNoise2D_NLM_GW_modPrior_plus, ...
    @deNoise2D_NLM_GW_euc, @deNoise2D_NLM_GW_Euc_modPrior, ...
    @deNoise2D_NLM_GW_euc_plus, @deNoise2D_NLM_GW_euc_modPrior_plus, ...
    @deNoise2D_PND, @deNoise2D_PND_modPrior, ...
    @deNoise2D_PND_Euc, @deNoise2D_PND_Euc_modPrior };
  imgFiles = { 'lena.png', 'boat.png', 'mandrill.png', 'barbara.png', ...
    'comedian.png' };
  color = false;
  noises = [ 8, 20, 25, 35, 40 ];
  noiseMean = 0;

  if isunix
      fileSepChar = '/';
      inDir = ['../../data/images'];
      addpath('./matlab-ParforProgress2') % Add path for parallel progress tracking
  else
      fileSepChar = '\';
      inDir = ['..\..\data\images'];
      addpath('.\matlab-ParforProgress2') % Add path for parallel progress tracking
  end

  % Make output preparations
  dateTime = datestr(now);
  dateTime = strrep(dateTime, ':', '');
  dateTime = strrep(dateTime, '-', '');
  dateTime = strrep(dateTime, ' ', '_');
  outDir = ['output_',dateTime];
  mkdir(outDir);

  logID = fopen([outDir,fileSepChar,'log.csv'], 'w');
  fprintf( logID, 'function, filename, noiseSig, runtime (sec), MSE, Paper MSE, PSNR\n');

  % NLM CONFIGURATION VALUES (NOMINAL)
  config = struct();
  config.kSize = 7;
  config.searchSize = 21; %nominal value is 21
  config.noiseMean = 0;
  config.color = color;
  config.hEuclidian = 8;

  % Process Images
  nImgs = numel(imgFiles);
  for imgIndx=1:nImgs
    disp(['Working on image ', num2str(imgIndx),' of ', num2str(nImgs)]);

    imgFile = [ inDir, fileSepChar, imgFiles{imgIndx} ];
    img = imread( imgFile );
    img = double( img )/255.;

    if color && ndims(img)<3 continue; end

    nNoises = numel(noises);
    for noiseIndx=1:nNoises
      disp(['Working on noise index ', num2str(noiseIndx), ...
        ' of ', num2str(nNoises)]);
      noiseSig = noises(noiseIndx);

      config.noiseSig = noiseSig/255; %standard deviation!
      config.h = 12*config.noiseSig;

      sImg = size(img);
      noise = normrnd( noiseMean, config.noiseSig, sImg(1), sImg(2) );
      if color
        noisyImg = img;
        noisyImg(:,:,1) = img(:,:,1) + noise;
        noisyImg(:,:,2) = img(:,:,2) + noise;
        noisyImg(:,:,3) = img(:,:,3) + noise;
      else
        if ndims( img ) > 2 img = rgb2gray( img ); end;
        noisyImg = img + noise;
      end
      noisyImg = min( max( noisyImg, 0 ), 1 );
      imwrite( noisyImg, [outDir,fileSepChar,'noisy_sig', ...
        num2str(noiseSig),'_',imgFiles{imgIndx}] );

      nAlgorithms = numel(algorithms);
      for algIndx=1:nAlgorithms
        disp(['Working on algorithm index ', num2str(algIndx), ...
          ' of ', num2str(nAlgorithms)]);

        % TEST SUITE CONFIGURATION
        config.testSuiteAddNoise = true; %if false, will not add noise to the image. used when imputting images with noise already present.
        config.testSuiteUseExternalImage = false; %if true, will not read in any images, but will process based on what you pass in
        %config.testSuiteExternalImage = imread('../../data/images/lena.png');
        %UseExternalImage flag overrides UseImages flag
        config.testSuiteUseImages = imgFiles{imgIndx}; %ex: testSuiteUseImages = {'lena.png', 'boat.png'} will only run on the two images, but empty {} runs all
        config.fileName = imgFile;

        algorithmHandle = algorithms{algIndx};
        tic
        output = algorithmHandle(noisyImg, config);
        runtime = toc;

        outFile = [ output.prefix, 'sig', num2str(noiseSig),'_', ...
          imgFiles{imgIndx}]
        deNoisedFile = [outDir, fileSepChar, outFile];
        imwrite( output.deNoisedImg, deNoisedFile );

        magDiffImg = abs( img - output.deNoisedImg );
        imwrite( magDiffImg, [outDir, fileSepChar, output.prefix, ...
          'diff_sig',num2str(noiseSig),imgFiles{imgIndx}] );

        magDiffImg255 = 255 * magDiffImg;
	logDiff = log( max( magDiffImg255, 1 ) );
        imwrite( magDiffImg255, [outDir, fileSepChar, output.prefix, ...
          'logDiff_sig',num2str(noiseSig),imgFiles{imgIndx}] );

        %calculate mse
        mse = calculateMSE( img, output.deNoisedImg, output.borderSize );
        paperMse = mse*255^2;
        psnr = calculatePSNR( img, output.deNoisedImg, output.borderSize );

        algString = func2str(algorithms{algIndx});
        imgString = ['=HYPERLINK(".',fileSepChar,outFile,'")'];
        fprintf( logID, '%s,%s, %f, %f, %f, %f, %f\n', algString, ...
          imgString, noiseSig, runtime, mse, paperMse, psnr);

        pause(1);  %Make sure all data gets written
        disp(['Completed Algorithm ', func2str(algorithmHandle)]);
      end
    end
  end

  disp('Program complete');
end
