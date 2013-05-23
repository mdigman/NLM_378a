function run_deNoiseAudio_NLM_GW_euclidian

% FUNCTION HANDLE
algorithmHandle = @deNoiseAudio_NLM_GW_euclidian;

% NLM CONFIGURATION VALUES (NOMINAL)
config = struct();
config.kSize = 301;
config.searchSize = 487; %Must be odd number.
config.noiseSig = 0.1; %standard deviation!
config.h = 18*config.noiseSig;
config.noiseMean = 0;

% TEST SUITE CONFIGURATION
config.testSuiteAddNoise = true; %if false, will not add noise to the image. used when imputting images with noise already present.
config.testSuiteUseExternalAudio = false; %if true, will not read in any images, but will process based on what you pass in
%[config.testSuiteExternalAudio, config.testSuiteExternalAudioFs] = audioread('../../data/audio/onandon.mp3');
%UseExternalImage flag overrides UseImages flag
config.testSuiteUseAudioFiles = {'onandon_snippet_mono.wav'}; %ex: testSuiteUseImages = {'lena.png', 'boat.png'} will only run on the two images, but empty {} runs all

% OTHER CONFIG VALUES
config.hEuclidian=8; %50/255 causes weights to converge to a single pixel

test_suite(algorithmHandle, config);

end
