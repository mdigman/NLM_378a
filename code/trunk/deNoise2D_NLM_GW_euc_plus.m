function output = deNoise2D_NLM_GW_Euc_plus( noisyImg, config )

  kSize = config.kSize;
  searchSize = config.searchSize;
  h = config.h;
  noiseSig = config.noiseSig;
  color = config.color;

  halfSearchSize = floor( searchSize/2 );
  halfKSize = floor( kSize/2 );

  bayes_dist_offset = sqrt(2*kSize^2 -1);

  hEuclidian = config.hEuclidian;
  hSqEuclidian = hEuclidian^2;

  eucDistsSq =  ones(searchSize,1)*((1:searchSize) -ceil(searchSize/2));
  eucDistsSq = eucDistsSq.^2 + (eucDistsSq').^2;

  a = 0.5*(kSize-1)/2;
  gaussKernel = fspecial('gaussian', kSize, a);
  if color
    [M N C] = size( noisyImg );
    gaussKernel = repmat(gaussKernel, [1 1 3]);
  else
    [M N] = size( noisyImg );
  end

  deNoisedImg = noisyImg;

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

  dists = zeros( searchSize, searchSize);

  %-- perform algorithm
  parfor j=borderSize:M-borderSize
    for i=borderSize:N-borderSize

      if color
        kernel = noisyImg( j-halfKSize:j+halfKSize, ...
          i-halfKSize:i+halfKSize, :);
      else
        kernel = noisyImg( j-halfKSize:j+halfKSize, ...
          i-halfKSize:i+halfKSize );
      end

      for jP=0:searchSize-1
        for iP=0:searchSize-1
          %disp(['(jP,iP): (',num2str(jP),',',num2str(iP),')']);

          vJ = j-halfSearchSize+jP;
          vI = i-halfSearchSize+iP;

          if color
            v = noisyImg( vJ-halfKSize : vJ+halfKSize, ...
              vI-halfKSize : vI+halfKSize, : );
          else
            v = noisyImg( vJ-halfKSize : vJ+halfKSize, ...
              vI-halfKSize : vI+halfKSize  );
          end

          distSq = ( kernel - v ) .* ( kernel - v );
          weightedDistSq = distSq.*gaussKernel*kSize^2;
          dists( jP+1, iP+1 ) = sqrt(sum( weightedDistSq(:) )); %L2 distance
        end
      end

      %Non-vectorized Bayesian Non-Local means weights
      localWeights = exp( -0.5*(dists/noiseSig - bayes_dist_offset).^2 ).*...
        exp( - eucDistsSq / hSqEuclidian );
      localWeights(halfSearchSize+1,halfSearchSize+1) = ...
        max( localWeights(:) );

      localWeights = localWeights / sum( localWeights(:) );
      if color
        localWeights = repmat( localWeights, [1 1 3] );
      end

      subImg = noisyImg( j-halfSearchSize : j+halfSearchSize, ...
        i-halfSearchSize : i+halfSearchSize, : );

      deNoisedImg(j,i,:) = sum( sum( localWeights .* subImg ) ) ;

    end

    %if mod(j,50)==0
    %  imshow( [noisyImg, deNoisedImg], [] );
    %  drawnow;
    %end

    ppm.increment(j);
  end


  %-- clean up parallel
  try % use try / catch here, since delete(struct) will raise an error.
    delete(ppm);
  catch me %#ok<NASGU>
  end


  %-- copy output images
  output = struct();
  output.deNoisedImg = deNoisedImg;
  output.prefix = 'NLM_GW_Euc_plus_';
  output.borderSize = borderSize;

end
