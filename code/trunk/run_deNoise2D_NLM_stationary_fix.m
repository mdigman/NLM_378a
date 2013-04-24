% FUNCTION HANDLE
algorithmHandle = @deNoise2D_NLM_stationary_fix;

% NLM CONFIGURATION VALUES (NOMINAL)
config = struct();
config.kSize = 7;
config.searchSize = 21;
config.noiseSig = 20/255; %standard deviation!
config.h = 10*config.noiseSig;
config.noiseMean = 0;

% STATIONARY FIX CONFIGURATION VALUES
config.varianceCutoff = 5*config.noiseSig^2;

if isunix
  test_suite_unix(algorithmHandle, config);
else
  test_suite(algorithmHandle, config);
end