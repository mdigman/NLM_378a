function run_deNoiseAudio_NLM

% FUNCTION HANDLE
algorithmHandle = @deNoiseAudio_NLM;

% NLM CONFIGURATION VALUES (NOMINAL)
config = struct();
config.kSize = 200;
config.searchSize = 1049; %nominal value is 21. Must be odd number.
config.noiseSig = 0.01; %standard deviation!
config.h = 12*config.noiseSig;
config.noiseMean = 0;

% TEST SUITE CONFIGURATION
config.testSuiteAddNoise = false; %if false, will not add noise to the image. used when imputting images with noise already present.
config.testSuiteUseExternalAudio = false; %if true, will not read in any images, but will process based on what you pass in
%[config.testSuiteExternalAudio, config.testSuiteExternalAudioFs] = audioread('../../data/audio/onandon.mp3');
%UseExternalImage flag overrides UseImages flag
config.testSuiteUseAudioFiles = {'lipatti_schumann_snippet1.wav'}; %ex: testSuiteUseImages = {'lena.png', 'boat.png'} will only run on the two images, but empty {} runs all

test_suite(algorithmHandle, config);

end
