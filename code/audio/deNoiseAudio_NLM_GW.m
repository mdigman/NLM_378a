function output = deNoiseAudio_NLM_GW( noisyAudio, config )
  %Uses gaussian weighted L2 norm


  kSize = config.kSize;
  searchSize = config.searchSize;
  h = config.h;
  %noiseSig = config.noiseSig;

  halfSearchSize = floor( searchSize/2 );
  halfKSize = floor( kSize/2 );
  hSq = h*h;

  a = 0.5*(kSize-1)/2;

  % wavread/audioread will return the audio channels in column vectors
  [M, numChannels] = size( noisyAudio );
  
  %Define the gaussian kernel for the gaussian weighted L2-norm
  gaussKernel = fspecial('gaussian', [kSize 1], a)*kSize^2;
  gaussKernel = repmat(gaussKernel, [1 numChannels]);

  deNoisedAudio = noisyAudio;

  borderSize = halfKSize+halfSearchSize+1;

  %% initialize progress tracker
  try % Initialization
    ppm = ParforProgressStarter2(config.fileName, M-2*borderSize, 0.1);
  catch me % make sure "ParforProgressStarter2" didn't get moved to a different directory
    if strcmp(me.message, 'Undefined function or method ''ParforProgressStarter2'' for input arguments of type ''char''.')
      error('ParforProgressStarter2 not in path.');
    else
      % this should NEVER EVER happen.
      msg{1} = 'Unknown error while initializing "ParforProgressStarter2":';
      msg{2} = me.message;
      print_error_red(msg);
      % backup solution so that we can still continue.
      ppm.increment = nan(1, N);
    end
  end


  %% perform algorithm
  for j=borderSize:M-borderSize
    % As far as I (Thomas) know, noisyImg can't be easily sliced to
    % improve performance. Instead, one would have to use spmd to do
    % such things. However, most of the time is spent in the two inner
    % loops anyway

    kernel = noisyAudio( j-halfKSize:j+halfKSize, : );
    localWeights = zeros( searchSize, numChannels );


    for jP=0:searchSize-1
      vJ = j-halfSearchSize+jP;

      v = noisyAudio( vJ-halfKSize : vJ+halfKSize, : );

      %Gaussian weighted L2 norm squared
      distSq = ( kernel - v ) .* ( kernel - v );
      weightedDistSq = distSq.*gaussKernel;
      weightedDistSq = sum( weightedDistSq(:) );

      localWeights( jP+1, : ) = exp( - weightedDistSq ./ hSq );
    end
    
    divisionSum =  ones(searchSize,1) * sum( localWeights, 1 );
    localWeights = localWeights ./ divisionSum;

    subAudio = noisyAudio( j-halfSearchSize : j+halfSearchSize, : );

    deNoisedAudio(j,:) = sum( localWeights .* subAudio, 1 ) ;
    
    ppm.increment(j);
  end


  %% clean up parallel
  try % use try / catch here, since delete(struct) will raise an error.
    delete(ppm);
  catch me %#ok<NASGU>
  end

  %% copy output audio
  output = struct();
  output.deNoisedAudio = deNoisedAudio;
  output.prefix = 'NLM_GW_';
  output.borderSize = borderSize;
end