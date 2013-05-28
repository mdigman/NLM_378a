function output = deNoiseAudio_NLM_euc_modPrior_plus( noisyAudio, config )
  %-- Uses gaussian weighted L2 norm

  kSize = config.kSize;
  searchSize = config.searchSize;
  h = config.h;
  noiseSig = config.noiseSig;

  hEuclidian = config.hEuclidian;
  hSqEuclidian = hEuclidian^2;

  lambda = 1;

  halfSearchSize = floor( searchSize/2 );
  halfKSize = floor( kSize/2 );

  bayes_dist_offset = sqrt(2*kSize^2 -1);

  eucDistsSq = ((1:searchSize)' -ceil(searchSize/2)).^2;

  a = 0.5*(kSize-1)/2;
  [M, numChannels] = size( noisyAudio );
  
  gaussKernel = fspecial('gaussian', [kSize 1], a)*kSize^2;
  gaussKernel = repmat(gaussKernel, [1 numChannels]);

  smoothedAudio = imfilter(noisyAudio, gaussKernel, 'replicate');
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
%   parfor j=borderSize:M-borderSize
%     kernel = noisyAudio( j-halfKSize:j+halfKSize, :);
%     %search = noisyAudio( j-halfSearchSize:j+halfSearchSize, : );
%     corrKer = smoothedAudio( j-halfKSize:j+halfKSize, :);
%     corrSearch = smoothedAudio( j-halfSearchSize:j+halfSearchSize, : );
%     %localWeights = zeros( searchSize, searchSize , 3);
%     dists = zeros( searchSize, numChannels);
% 
%     C_array = [];
%     % FIXME: replace normxcorr2 with xcorr(a, b, 'coeff')
%     for i=1:numChannels
%       C_array(:,i) = normxcorr2(corrKer(:,i), corrSearch(:,i) );
%     end
%     C = sum(C_array, 2) / size(C_array, 2);
% 
%     % FIXME: if I only select a subsection, why calculate the normxcorr2
%     % over the whole range?
%     C = C( halfKSize+1:end-halfKSize );
% 
%     for jP=0:searchSize-1
%       vJ = j-halfSearchSize+jP;
% 
%       v = noisyAudio( vJ-halfKSize : vJ+halfKSize, : );
% 
%       %Gaussian weighted L2 norm squared
%       distSq = ( kernel - v ) .* ( kernel - v );
%       dists( jP+1, :) = sqrt(sum( distSq(:) )); %L2 distance
%     end
% 
%     %Non-vectorized Bayesian Non-Local means weights
%     localWeights = exp( -0.5*(dists/noiseSig - bayes_dist_offset).^2 ).*...
%       exp( - eucDistsSq / hSqEuclidian );
% 
%     C = max( C, 0 );
%     
%     varKer_array = [];
%     for i=1:numChannels
%       varKer_array(:,i) = var(corrKer(:,i));
%     end
%     varKer = sum(varKer_array, 2) / size(varKer_array, 2);
%     
%     prior = C + exp( -( lambda * varKer) ) * (1-C);
%     prior = prior / ( sum(prior));
%     
%     localWeights(:,1) = localWeights(:,1) .* prior;
%     
%     divisionSum = sum( localWeights(:,1), 1 );
%     localWeights = localWeights ./ divisionSum;
%   
%     subAudio = noisyAudio( j-halfSearchSize : j+halfSearchSize, : );
% 
%     deNoisedAudio(j,:) = sum( localWeights .* subAudio, 1 ) ;
% 
%     ppm.increment(j);
%   end

  %-- perform algorithm
  parfor j=borderSize:M-borderSize
    kernel = noisyAudio( j-halfKSize:j+halfKSize );
    %search = noisyAudio( j-halfSearchSize:j+halfSearchSize );
    corrKer = smoothedAudio( j-halfKSize:j+halfKSize );
    corrSearch = smoothedAudio( j-halfSearchSize:j+halfSearchSize );
    %localWeights = zeros( searchSize );
    dists = zeros( searchSize, 1 );
    % TODO: It doesn't normalize!
    C = normxcorr2(corrKer, corrSearch);
    % original: 
    C = C( halfKSize+1:end-halfKSize, 1 );
    %C = C( halfKSize+1:searchSize+halfKSize, 1 );

    for jP=0:searchSize-1
        vJ = j-halfSearchSize+jP;


        v = noisyAudio( vJ-halfKSize : vJ+halfKSize );

        %Gaussian weighted L2 norm squared
        distSq = ( kernel - v ) .* ( kernel - v );
        dists( jP+1, :) = sqrt(sum( distSq(:) )); %L2 distance
    end

    %Non-vectorized Bayesian Non-Local means weights
    localWeights = exp( -0.5*(dists/noiseSig - bayes_dist_offset).^2 ).*...
      exp( - eucDistsSq / hSqEuclidian );

    C = max( C, 0 );
    varKer = var( corrKer(:) );
    
    prior = C + exp( -( lambda * varKer) ) * (1-C);
    prior = prior / sum(prior);
    
    localWeights = localWeights .* prior;
    localWeights = localWeights / sum( localWeights(:) );
  
    subAudio = noisyAudio( j-halfSearchSize : j+halfSearchSize, : );

    deNoisedAudio(j,:) = sum( sum( localWeights .* subAudio ) ) ;
  
    
    %if mod(j,50)==0
    %  imshow( [noisyImg, deNoisedImg], [] );
    %  drawnow;
    %end
    
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
  output.prefix = 'NLM_euc_modPrior_plus_';
  output.borderSize = borderSize;
end