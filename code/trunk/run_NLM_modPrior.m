function run_NLM_modPrior

  % FUNCTION HANDLE
  algorithmHandle = @deNoise2D_NLM_modPrior;

  % NLM CONFIGURATION VALUES (NOMINAL)
  config = struct();
  config.kSize = 7;
  config.searchSize = 21; %nominal value is 21
  config.noiseSig = 20/255; %standard deviation!
  config.h = 12*config.noiseSig;
  config.noiseMean = 0;

  % TEST SUITE CONFIGURATION
  config.testSuiteAddNoise = true; %if false, will not add noise to the image. used when imputting images with noise already present.
  config.testSuiteUseExternalImage = false; %if true, will not read in any images, but will process based on what you pass in
  config.color = false; %if true, will not convert to gray scale and will compute similarities based on color (RGB)

  %test 1
  config.noiseSig = 20/255;
  config.h = 12*config.noiseSig;
  config.testSuiteUseImages = {'lena.png'};
  %config.testSuiteUseImages = {'barbara.png','lena.png','mandrill.png', ...
  %  'comedian.png', 'boat.png', 'airplane.bmp', 'goldhill.bmp'};
  test_suite(algorithmHandle, config);

end