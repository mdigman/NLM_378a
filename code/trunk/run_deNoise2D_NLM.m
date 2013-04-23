% FUNCTION HANDLE
algorithmHandle = @deNoise2D_NLM;

% NLM CONFIGURATION VALUES (NOMINAL)
config = struct();
config.kSize = 7;
config.searchSize = 21;
config.noiseSig = 20/255; %standard deviation!
config.h = 10*config.noiseSig;
config.noiseMean = 0;

test_suite(algorithmHandle, config);