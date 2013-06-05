function run_PND_modPrior_color

% FUNCTION HANDLE
algorithmHandle = @deNoise2D_PND_modPrior_color;

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
config.color = true; %if true, will not convert to gray scale and will compute similarities based on color (RGB)

% OTHER CONFIG VALUES
config.hEuclidian=8; %50/255 causes weights to converge to a single pixel

%test 1
config.noiseSig = 8/255;
config.h = 12*config.noiseSig;
config.testSuiteUseImages = {'barbara.png','lena.png','mandrill.png', 'airplane.bmp', 'goldhill.bmp'};
%     'comedian.png', 'boat.png'
test_suite(algorithmHandle, config);

end