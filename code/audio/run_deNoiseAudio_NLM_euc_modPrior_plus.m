function run_deNoiseAudio_NLM_euc_modPrior_plus

% FUNCTION HANDLE
algorithmHandle = @deNoiseAudio_NLM_euc_modPrior_plus;

% NLM CONFIGURATION VALUES (NOMINAL)
config = struct();
config.kSize = 301;
config.searchSize = 3001; %nominal value is 21
config.noiseSig = 0.01; %standard deviation!
config.h = 12*config.noiseSig;
config.noiseMean = 0;

% TEST SUITE CONFIGURATION
config.testSuiteAddNoise = false; %if false, will not add noise to the image. used when imputting images with noise already present.
config.testSuiteUseExternalImage = false; %if true, will not read in any images, but will process based on what you pass in
config.testSuiteUseAudioFiles = {'lipatti_schumann_snippet1.wav'}; %ex: testSuiteUseImages = {'lena.png', 'boat.png'} will only run on the two images, but empty {} runs all

config.hEuclidian=4000; %50/255 causes weights to converge to a single pixel

test_suite(algorithmHandle, config);
end