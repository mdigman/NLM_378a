function mse = calculateMSE( origAudio, deNoisedAudio, border )

  if nargin < 3
    border = 0;
  end

  N = size( origAudio, 1 );

 
  subOrig = origAudio( border+1:N-border, : );
  subDenoised = deNoisedAudio( border+1:N-border, : );
 
  tmp = subOrig - subDenoised;
  tmp = tmp .* tmp;
  mse = sum( tmp(:) ) / numel(tmp);
end

