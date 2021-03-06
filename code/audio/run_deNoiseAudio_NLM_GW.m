function run_deNoiseAudio_NLM_GW
  % FUNCTION HANDLE
  algorithmHandle = @deNoiseAudio_NLM_GW;

  % NLM CONFIGURATION VALUES (NOMINAL)
  config = struct();
  config.kSize = 301;
  config.searchSize = 3001; %nominal value is 21
  config.noiseSig = 0.05;
  config.noiseMean = 0;

  % TEST SUITE CONFIGURATION
  config.testSuiteAddNoise = true; %if false, will not add noise to the image. used when imputting images with noise already present.
  config.testSuiteUseAudioFiles = {'fluteShort_mono_snippet.wav'};

  % GW configuration values
  config.h = 12*config.noiseSig;
  
  test_suite(algorithmHandle, config);
end