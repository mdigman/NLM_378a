function output = deNoiseAudio_NLM_GW_gaussian_samp( noisyAudio, config )
  %Uses gaussian weighted L2 norm


  kSize = config.kSize;
  h = config.h;
  %noiseSig = config.noiseSig;
  halfKSize = floor( kSize/2 );
  hSq = h*h;

  a = 0.5*(kSize-1)/2;
  searchPoints = config.searchPoints;
  effectiveSearchWindow = config.effectiveSearchWindow;
  aSearchWindow = 0.5*(effectiveSearchWindow-1)/2;

  [M, numChannels] = size( noisyAudio );
  %Define the gaussian kernel for the gaussian weighted L2-norm
  gaussKernel = fspecial('gaussian', kSize, a)*kSize^2;

  deNoisedAudio = noisyAudio;

  borderSize = halfKSize+1;

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
  parfor j=borderSize:M-borderSize
    % As far as I (Thomas) know, noisyAudio can't be easily sliced to
    % improve performance. Instead, one would have to use spmd to do
    % such things. However, most of the time is spent in the two inner
    % loops anyway

    kernel = noisyAudio( j-halfKSize:j+halfKSize, :);
    localWeights = zeros( searchPoints, numChannels);


    %generate searchPoints non-repeating pixel locations using gaussian
    %probability centered at j,i
    pointsToUse = round(normrnd(0,aSearchWindow, 1, searchPoints));
    pointsToUse(1,:) = pointsToUse(1,:) + j;
    if any(pointsToUse(1,:) < borderSize)
      pointsToUse(1, pointsToUse(1,:) < borderSize ) = borderSize;
    elseif any(pointsToUse(1,:) > M-borderSize)
      pointsToUse(1,pointsToUse(1,:) > M-borderSize) = M-borderSize;
    end

    %each column represents a new pixel location

    for k = 1:searchPoints
      vJ = pointsToUse(1, k);
      v = noisyAudio( vJ-halfKSize : vJ+halfKSize, : );

      %Gaussian weighted L2 norm squared
      distSq = ( kernel - v ) .* ( kernel - v );
      weightedDistSq = distSq.*gaussKernel;
      weightedDistSq = sum( weightedDistSq(:) );

      localWeights( k ,: ) = exp( - weightedDistSq / hSq );
    end


    denoisedSum = 0;
    localWeights = localWeights ./ sum( localWeights, 1 );
    for k=1:searchPoints
      vJ = pointsToUse(1, k);
      w = zeros(1,numChannels);
      w(:) = localWeights(k,:);
      denoisedSum = denoisedSum + noisyAudio(vJ, :).*w;
    end

    deNoisedAudio(j,:) = denoisedSum;


    ppm.increment(j);
  end


  %% clean up parallel
  try % use try / catch here, since delete(struct) will raise an error.
    delete(ppm);
  catch me %#ok<NASGU>
  end

  %% copy output images
  output = struct();
  output.deNoisedAudio = deNoisedAudio;
  output.prefix = 'NLM_GW_gaussian_samp';
  output.borderSize = borderSize;
end