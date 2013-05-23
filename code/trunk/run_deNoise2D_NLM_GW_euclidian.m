function run_deNoise2D_NLM_GW_euclidian

% FUNCTION HANDLE
algorithmHandle = @deNoise2D_NLM_GW_euclidian;

% NLM CONFIGURATION VALUES (NOMINAL)
config = struct();
config.kSize = 7;
config.searchSize = 5; %nominal value is 21
config.noiseSig = 20/255; %standard deviation!
config.h = 12*config.noiseSig;
config.noiseMean = 0;
config.color = true;

% TEST SUITE CONFIGURATION
config.testSuiteAddNoise = true; %if false, will not add noise to the image. used when imputting images with noise already present.
config.testSuiteUseExternalImage = false; %if true, will not read in any images, but will process based on what you pass in
%config.testSuiteExternalImage = imread('../../data/images/lena.png');
%UseExternalImage flag overrides UseImages flag
config.testSuiteUseImages = {'lena.png'}; %ex: testSuiteUseImages = {'lena.png', 'boat.png'} will only run on the two images, but empty {} runs all

% OTHER CONFIG VALUES
config.hEuclidian=8; %50/255 causes weights to converge to a single pixel

test_suite(algorithmHandle, config);

end