function run_deNoiseAudio_NLM_euc_modPrior_plus

% FUNCTION HANDLE
algorithmHandle = @deNoiseAudio_NLM_euc_modPrior_plus;

% NLM CONFIGURATION VALUES (NOMINAL)
config = struct();
config.kSize = 301;
config.searchSize = 3001; %nominal value is 21
config.noiseSig = 0.05; %standard deviation!
config.noiseMean = 0;

% TEST SUITE CONFIGURATION
config.testSuiteAddNoise = true; %if false, will not add noise to the image. used when imputting images with noise already present.
config.testSuiteUseAudioFiles = {'fluteShort_mono.wav'};

config.hEuclidian=4000; %50/255 causes weights to converge to a single pixel

test_suite(algorithmHandle, config);
end