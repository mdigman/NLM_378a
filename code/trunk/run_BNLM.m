function run_BNLM

% FUNCTION HANDLE
algorithmHandle = @deNoise2D_BNLM;

% NLM CONFIGURATION VALUES (NOMINAL)
config = struct();
config.kSize = 7;
config.searchSize = 21; %nominal value is 21
config.noiseSig = 20/255; %standard deviation!
config.noiseMean = 0;

%config.h = 12*config.noiseSig; 

% TEST SUITE CONFIGURATION
config.testSuiteAddNoise = true; %if false, will not add noise to the image. used when imputting images with noise already present.
config.testSuiteUseExternalImage = false; %if true, will not read in any images, but will process based on what you pass in
config.color = false; %if true, will not convert to gray scale and will compute similarities based on color (RGB)

%test 1
%config.noiseSig = 8/255;
%config.h = 12*config.noiseSig;
%config.testSuiteUseImages = {'boat.png'};
%test_suite(algorithmHandle, config);

%test 2
config.noiseSig = 20/255;
config.h = 12*config.noiseSig;
config.testSuiteUseImages = {'lena.png'};
test_suite(algorithmHandle, config);

%test 3
%config.noiseSig = 25/255;
%config.h = 12*config.noiseSig;
%config.testSuiteUseImages = {'barbara.png'};
%test_suite(algorithmHandle, config);

%test 4
%config.noiseSig = 35/255;
%config.h = 12*config.noiseSig;
%config.testSuiteUseImages = {'mandrill.png'};
%test_suite(algorithmHandle, config);

end