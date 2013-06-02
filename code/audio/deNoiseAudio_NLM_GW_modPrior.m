function output = deNoiseAudio_NLM_GW_modPrior( noisyAudio, config )
  %-- Uses gaussian weighted L2 norm

  kSize = config.kSize;
  searchSize = config.searchSize;
  h = config.h;
  hSq = h^2;

  lambda = 1;

  halfSearchSize = floor( searchSize/2 );
  halfKSize = floor( kSize/2 );

  a = 0.5*(kSize-1)/2;
  [M, numChannels] = size(noisyAudio);

  gaussKernel = fspecial('gaussian', [kSize 1], a)*kSize;
  gaussKernel = repmat(gaussKernel, [1 numChannels]);

  smoothedAudio = imfilter(noisyAudio, gaussKernel, 'replicate');
  deNoisedAudio = noisyAudio;

  borderSize = halfKSize+halfSearchSize+1;

  %-- initialize progress tracker
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


  %-- perform algorithm
  parfor j=borderSize:M-borderSize
    halfCorrSearchSize = halfSearchSize+halfKSize;
    kernel = noisyAudio( j-halfKSize:j+halfKSize, :);
    corrKer = smoothedAudio( j-halfKSize:j+halfKSize, :);
    corrSearch = smoothedAudio( j-halfCorrSearchSize:j+halfCorrSearchSize, : );
    localWeights = zeros( searchSize , numChannels);
    
    C_array = [];
    for i=1:numChannels
      C_array(:,i) = normxcorr2(corrKer(:,i), corrSearch(:,i) );
    end
    C = sum(C_array, 2) / size(C_array, 2);
     
%     if color
%       kernel = noisyAudio( j-halfKSize:j+halfKSize, ...
%         i-halfKSize:i+halfKSize, :);
%       corrKer = smoothedAudio( j-halfKSize:j+halfKSize, ...
%         i-halfKSize:i+halfKSize, :);
%       corrSearch = smoothedAudio( j-halfCorrSearchSize:j+halfCorrSearchSize, ...
%         i-halfCorrSearchSize:i+halfCorrSearchSize, : );
%       localWeights = zeros( searchSize, searchSize , 3);
%       C1 = normxcorr2(corrKer(:,:,1), corrSearch(:,:,1) );
%       C2 = normxcorr2(corrKer(:,:,2), corrSearch(:,:,2) );
%       C3 = normxcorr2(corrKer(:,:,3), corrSearch(:,:,3) );
%       C = ( C1 + C2 + C3 ) / 3;
%     else
%       kernel = noisyImg( j-halfKSize:j+halfKSize, ...
%         i-halfKSize:i+halfKSize );
%       corrKer = smoothedAudio( j-halfKSize:j+halfKSize, ...
%         i-halfKSize:i+halfKSize);
%       corrSearch = smoothedAudio( j-halfCorrSearchSize:j+halfCorrSearchSize, ...
%         i-halfCorrSearchSize:i+halfCorrSearchSize );
%       localWeights = zeros( searchSize, searchSize );
%       C = normxcorr2(corrKer, corrSearch);
%     end
    
    % FIXME: if I only select a subsection, why calculate the normxcorr2
    % over the whole range?
    C = C( 2*halfKSize+1:end-2*halfKSize );

    
    for jP=0:searchSize-1
      vJ = j-halfSearchSize+jP;

      v = noisyAudio( vJ-halfKSize : vJ+halfKSize, : );
      
      %Gaussian weighted L2 norm squared
      distSq = ( kernel - v ) .* ( kernel - v );
      weightedDistSq = distSq.*gaussKernel;
      localWeights( jP+1, :) = sum( weightedDistSq, 1 );
    end

    localWeights = exp( -localWeights/hSq );

    C = max( C, 0 );
    
    varKer_array = [];
    for i=1:numChannels
      varKer_array(:,i) = var(corrKer(:,i));
    end
    varKer = sum(varKer_array, 2) / size(varKer_array, 2);
    
    prior = C + exp( -( lambda * varKer) ) * (1-C);
    prior = prior / ( sum(prior));
    
    for iChannel = 1:numChannels
      localWeights(:,iChannel) = localWeights(:,iChannel) .* prior / sum(localWeights(:,iChannel));
    end

    subAudio = noisyAudio( j-halfSearchSize : j+halfSearchSize, : );

    deNoisedAudio(j,:) = sum( localWeights .* subAudio, 1 );

    ppm.increment(j);
  end


  %-- clean up parallel
  try % use try / catch here, since delete(struct) will raise an error.
    delete(ppm);
  catch me %#ok<NASGU>
  end


  %-- copy output images
  output = struct();
  output.deNoisedAudio = deNoisedAudio;
  output.prefix = 'NLM_GW_modPrior_';
  output.borderSize = borderSize;
end