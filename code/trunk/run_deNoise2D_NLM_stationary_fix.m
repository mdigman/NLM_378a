function run_deNoise2D_NLM_stationary_fix

  % FUNCTION HANDLE
  algorithmHandle = @deNoise2D_NLM_stationary_fix;

  % NLM CONFIGURATION VALUES (NOMINAL)
  config = struct();
  config.kSize = 7;
  config.searchSize = 5;
  config.noiseSig = 20/255; %standard deviation!
  config.h = 10*config.noiseSig;
  config.noiseMean = 0;

  % STATIONARY FIX CONFIGURATION VALUES
  config.varianceCutoff = 5*config.noiseSig^2;

  test_suite(algorithmHandle, config);

end
