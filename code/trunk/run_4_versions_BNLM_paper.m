function run_4_versions_BNLM_paper

% FUNCTION HANDLE
algorithmHandles = {@deNoise2D_NLM_plus, @deNoise2d_BNLM, ...
  @deNoise2D_NLM_modPrior_plus, @deNoise2D_NLM_euc_modPrior_plus,...
  @deNoise2D_NLM_euc_modPrior_plus};
  %Run euc twice with different hEuclidean
  
%Algorithm names
algorithmNames = {'deNoise2D_NLM_plus', 'deNoise2d_BNLM', ...
  'deNoise2D_NLM_modPrior_plus', 'deNoise2D_NLM_euc_modPrior_plus',...
  'deNoise2D_NLM_euc_modPrior_plus'};


% NLM CONFIGURATION VALUES (NOMINAL)
config = struct();
config.kSize = 7;
config.searchSize = 21; %nominal value is 21
config.noiseMean = 0;
config.noiseSig = 20/255;
config.h = 12*config.noiseSig; 


% TEST SUITE CONFIGURATION
config.testSuiteAddNoise = true; %if false, will not add noise to the image. used when imputting images with noise already present.
config.testSuiteUseExternalImage = false; %if true, will not read in any images, but will process based on what you pass in
config.color = false; %if true, will not convert to gray scale and will compute similarities based on color (RGB)

for i = 1:5
 
  algorithmHandle = algorithmHandles{i};
  config.algorithmName = algorithmNames{i};
  
  if (i == 4)
    config.hEuclidian=2;
  elseif (i == 5)
    config.hEuclidian=8;
  end
  
  %test 1
  config.noiseSig = 8/255;
  config.h = 12*config.noiseSig;
  config.testSuiteUseImages = {'boat.png'};
  test_suite(algorithmHandle, config);

  %test 2
  config.noiseSig = 20/255;
  config.h = 12*config.noiseSig;
  config.testSuiteUseImages = {'lena.png'};
  test_suite(algorithmHandle, config);

  %test 3
  config.noiseSig = 25/255;
  config.h = 12*config.noiseSig;
  config.testSuiteUseImages = {'barbara.png'};
  test_suite(algorithmHandle, config);

  %test 4
  config.noiseSig = 35/255;
  config.h = 12*config.noiseSig;
  config.testSuiteUseImages = {'mandrill.png'};
  test_suite(algorithmHandle, config);

end