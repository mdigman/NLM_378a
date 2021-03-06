function run_deNoiseMRI_NLM_condor

  manycores = parallel.importProfile('matlab/manycores.settings');
  matlabpool open manycores 12;

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
  else
      fileSepChar = '\';
      inDir = ['..\..\data\images'];
      addpath('.\matlab-ParforProgress2') % Add path for parallel progress tracking
      noisyFile = '..\..\data\brainWeb\pd_icbm_normal_1mm_pn5_rf20.mnc';
  end
    
  
  [noisyData,scaninfo] = loadminc(noisyFile);

  
  halfSearchSize = floor( config.searchSize/2 );
  halfKSize = floor( config.kSize/2 );
  borderSize = halfKSize+halfSearchSize+1;
  
  % Note:  14 is the border size
  subNoisyData = noisyData( 109-borderSize-8:109+borderSize+8, :, : );
  deNoiseMRI_NLM( subNoisyData, config );
  subDeNoised = output.deNoisedMRI;
  
  save('deNoisedMRI.mat', subNoisyData, subDeNoised );
  
  matlabpool close manycores;

end
