function psnr = calculatePSNR( origImg, deNoisedImg, border )

%see http://www.mathworks.com/help/vision/ref/psnr.html

if nargin < 3
    border = 0;
end

numDims = ndims( origImg );
sImg = size( origImg );
ny = sImg(1);
nx = sImg(2);

if numDims > 2 %in color
    origYCbCr = rgb2ycbcr(origImg);
    deNoisedYCbCr = rgb2ycbcr(deNoisedImg);
    mse = calculateMSE(origYCbCr(:,:,1), deNoisedYCbCr(:,:,1), border);
   
else
    mse = calculateMSE(origImg, deNoisedImg, border);  
end

%note, in current application image values are between 0 and 1
%for PSNR calc need mse for image values between 0 and 255 so scale
mse = mse*255^2;
psnr = 10*log10(255^2/mse);  
