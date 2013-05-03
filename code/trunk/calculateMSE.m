function mse = calculateMSE( origImg, deNoisedImg, border )

  if nargin < 3
    border = 0;
  end

  numDims = ndims( origImg );
  sImg = size( origImg );
  ny = sImg(1);
  nx = sImg(2);

  if numDims > 2
    subOrig = origImg( border+1:ny-border, border+1:ny-border, : );
    subDenoised = deNoisedImg( border+1:ny-border, border+1:ny-border, : );
  else
    subOrig = origImg( border+1:ny-border, border+1:ny-border );
    subDenoised = deNoisedImg( border+1:ny-border, border+1:ny-border );
  end

  tmp = subOrig - subDenoised;
  tmp = tmp .* tmp;
  mse = sum( tmp(:) ) / numel(tmp);
end

