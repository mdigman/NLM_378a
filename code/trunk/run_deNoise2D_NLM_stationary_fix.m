function run_deNoise2D_NLM_stationary_fix

% FUNCTION HANDLE
algorithmHandle = @deNoise2D_NLM_stationary_fix;
algorithmHandleOrig = @deNoise2D_NLM;

% NLM CONFIGURATION VALUES (NOMINAL)
config = struct();
config.kSize = 7;
config.searchSize = 5; %nominal value is 21
config.noiseSig = 10/255; %standard deviation!
config.h = 12*config.noiseSig;
config.noiseMean = 0;
config.color = false;

% Going to run the stationary fix algorithm against the original
% First generate the noisy image
img = imread('../../data/images/lena.png');
img = rgb2gray( img ); 
img = double( img )/255.;
sImg = size( img );
noise = normrnd( config.noiseMean, config.noiseSig, sImg(1), sImg(2) );
noisyImg = img + noise;
noisyImg = round(noisyImg*255);
noisyImg(noisyImg>255) = 255;

% TEST SUITE CONFIGURATION
config.testSuiteAddNoise = false; %if false, will not add noise to the image. used when imputting images with noise already present.
config.testSuiteUseExternalImage = true; %if true, will not read in any images, but will process based on what you pass in
config.testSuiteExternalImage = noisyImg;
%UseExternalImage flag overrides UseImages flag
config.testSuiteUseImages = {}; %ex: testSuiteUseImages = {'lena.png', 'boat.png'} will only run on the two images, but empty {} runs all

% STATIONARY FIX CONFIGURATION VALUES
config.varianceCutoff = 5*config.noiseSig^2;

test_suite(algorithmHandle, config);
test_suite(algorithmHandleOrig, config);

end
