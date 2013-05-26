function output = deNoiseMRI_eucNLMwModPriorPlus( noisyMRI, config )

  kSize = config.kSize;
  searchSize = config.searchSize;
  h = config.h;
  noiseSig = config.noiseSig;
  hEuclidian = config.hEuclidian;
  
  halfSearchSize = floor( searchSize/2 );
  halfKSize = floor( kSize/2 );
  hSq = h*h;
  hSqEuclidian = hEuclidian^2;

  bayes_dist_offset = sqrt(2*kSize^2 -1);

  eucDistsSq2D = ones(searchSize,1)*((1:searchSize)-ceil(searchSize/2));
  xEucDistsSq = repmat( eucDistsSq2D, [1, 1, searchSize] );
  yEucDistsSq = repmat( eucDistsSq2D', [1, 1, searchSize] );
  zEucDistsSq = permute( xEucDistsSq, [1 3 2] );
  
  eucDistsSq = xEucDistsSq.^2 + yEucDistsSq.^2 + zEucDistsSq.^2;

  [K M N] = size( noisyMRI );

  deNoisedMRI = noisyMRI;

  lambda = 1;

  a = 0.5*(kSize-1)/2;
  gaussKernel = fspecial('gaussian', kSize, a)*kSize^2;
  smoothedMRI = imfilter(noisyMRI, gaussKernel, 'replicate');

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
  parfor k=borderSize:K-borderSize
    %disp(['Working on slice, ', num2str(k)]);

    for j=borderSize:M-borderSize
      disp(['Working on slice/row ', num2str(k), ', ', num2str(j)]);

      for i=borderSize:N-borderSize
        %disp(['Working on slice/row/col ', ...
        %  num2str(k), ', ', num2str(j), ', ', num2str(i)]);

        kernel = noisyMRI( k-halfKSize:k+halfKSize, ...
          j-halfKSize:j+halfKSize, ...
          i-halfKSize:i+halfKSize, :);
        dists = zeros( searchSize, searchSize, searchSize );

        corrKer = smoothedMRI( k-halfKSize:k+halfKSize, ...
          j-halfKSize:j+halfKSize, ...
          i-halfKSize:i+halfKSize);
        corrSearch = smoothedMRI( k-halfSearchSize:k+halfSearchSize, ...
          j-halfSearchSize:j+halfSearchSize, ...
          i-halfSearchSize:i+halfSearchSize );

        C = normxcorr3(corrKer, corrSearch, 'same');
        
        for kP=0:searchSize-1
          for jP=0:searchSize-1
            for iP=0:searchSize-1
              %disp(['(jP,iP): (',num2str(jP),',',num2str(iP),')']);

              vK = k-halfSearchSize+kP;
              vJ = j-halfSearchSize+jP;
              vI = i-halfSearchSize+iP;

              v = noisyMRI( vK-halfKSize : vK+halfKSize, ...
                vJ-halfKSize : vJ+halfKSize, ...
                vI-halfKSize : vI+halfKSize );

              tmp = kernel - v;
              distSq = tmp .* tmp;
              dists( kP+1, jP+1, iP+1) = sqrt(sum( distSq(:) )); %L2 distance
            end
          end
        end

        localWeights = exp( -0.5*(dists/noiseSig - bayes_dist_offset).^2 ).*...
          exp( - eucDistsSq / hSqEuclidian );

        C = max( C, 0 );
        varKer = var( corrKer(:) );
        prior = C + exp( -( lambda * varKer) ) * (1-C);
        prior = prior / sum( prior(:) );
        localWeights = localWeights .* prior;
        localWeights = localWeights / sum( localWeights(:) );

        subMRI = noisyMRI( k-halfSearchSize : k+halfSearchSize, ...
            j-halfSearchSize : j+halfSearchSize, ...
            i-halfSearchSize : i+halfSearchSize, : );

        deNoisedMRI(k,j,i) = sum( localWeights(:) .* subMRI(:) );
      end

      %if mod(j,5)==0
      %  noisyImg = squeeze( noisyMRI(k,:,:) );
      %  deNoisedImg = squeeze( deNoisedMRI(k,:,:) );
      %  diffImg = noisyImg - deNoisedImg;
      %  imshow( [noisyImg, deNoisedImg, abs(diffImg)], [] );
      %  drawnow;
      %end
      
    end
    
    ppm.increment(j);
  end


  %-- clean up parallel
  try % use try / catch here, since delete(struct) will raise an error.
    delete(ppm);
  catch me %#ok<NASGU>
  end

  %-- copy output images
  output = struct();
  output.deNoisedMRI = deNoisedMRI;
  output.prefix = 'eucNLMwModPriorPlus_';
  output.borderSize = borderSize;
end
