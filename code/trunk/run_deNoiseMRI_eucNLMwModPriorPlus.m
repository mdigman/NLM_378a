function run_deNoiseMRI_eucNLMwModPriorPlus

  % FUNCTION HANDLE
  algorithmHandle = @deNoise2D_NLM;

  % NLM CONFIGURATION VALUES (NOMINAL)
  config = struct();
  config.kSize = 7;
  config.searchSize = 21; %nominal value is 21
  config.noiseSig = 20/255; %standard deviation!
  config.h = 12*config.noiseSig;
  config.noiseMean = 0;
  config.color = false;
  
  % OTHER CONFIG VALUES
  config.hEuclidian=8; %50/255 causes weights to converge to a single pixel

  % TEST SUITE CONFIGURATION
  config.testSuiteAddNoise = true; %if false, will not add noise to the image. used when imputting images with noise already present.
  config.testSuiteUseExternalImage = false; %if true, will not read in any images, but will process based on what you pass in
  %config.testSuiteExternalImage = imread('../../data/images/lena.png');
  %UseExternalImage flag overrides UseImages flag
  config.testSuiteUseImages = {'lena.png'};
    % ex: testSuiteUseImages = {'lena.png', 'boat.png'} will only run on the two images, 
    % but empty {} runs all
  config.fileName = 'pd_icbm_normal_1mm_pn5_rf20.mnc';

  if isunix
      fileSepChar = '/';
      inDir = ['../../data/images'];
      addpath('./matlab-ParforProgress2') % Add path for parallel progress tracking
      noisyFile = '../../data/brainWeb/pd_icbm_normal_1mm_pn5_rf20.mnc';
      imgsDir = '../../data/MRI/Series8_144_4CF9EA89.dcm_200';
      %imgsDir = '../../data/MRI/Series2_161_722100_222';
  else
      fileSepChar = '\';
      inDir = ['..\..\data\images'];
      addpath('.\matlab-ParforProgress2') % Add path for parallel progress tracking
      noisyFile = '..\..\data\brainWeb\pd_icbm_normal_1mm_pn5_rf20.mnc';
      imgsDir = '..\..\data\MRI\Series8_144_4CF9EA89.dcm_200';
      %imgsDir = '..\..\data\MRI\Series2_161_722100_222';
  end

  halfSearchSize = floor( config.searchSize/2 );
  halfKSize = floor( config.kSize/2 );
  borderSize = halfKSize+halfSearchSize+1;

  simulated = 0;
  nDataSlices = 3;
  % Note:  14 is the border size
  if simulated
    [noisyData,scaninfo] = loadminc(noisyFile);
    halfDataSlices = floor( nDataSlices / 2 );
    subNoisyData = noisyData( 109-borderSize-halfDataSlices : ...
                              109+borderSize+halfDataSlices, :, : );
  else
    noisyData = loadMriImages( imgsDir );
    halfDataSlices = floor( nDataSlices / 2 );
    subNoisyData = noisyData( :, :, 30-borderSize-halfDataSlices : ...
                              30+borderSize+halfDataSlices );
  end
  subNoisyData = subNoisyData / max( subNoisyData(:) );

  output = deNoiseMRI_eucNLMwModPriorPlus( subNoisyData, config );
  subDeNoised = output.deNoisedMRI;

  if simulated
    saveNoisyData = subNoisyData( borderSize+1:end-borderSize, :, : );
    saveDeNoised = subDeNoised( borderSize+1:end-borderSize, :, : );
  else
    saveNoisyData = subNoisyData( :, :, borderSize+1:end-borderSize );
    saveDeNoised = subDeNoised( :, :, borderSize+1:end-borderSize );
  end

  saveName = [output.prefix,'deNoisedMRI.mat'];
  save(saveName, 'subNoisyData', 'subDeNoised' );
  
end
