function output = deNoise2D_BNLM( noisyImg, config, origImg )

  kSize = config.kSize;
  searchSize = config.searchSize;
  color = config.color;

  halfSearchSize = floor( searchSize/2 );
  halfKSize = floor( kSize/2 );
  
  %Parameters for BNLM 
  noiseSig = config.noiseSig;
  bayes_dist_offset = sqrt(2*kSize^2 -1);
  mean_thresh = 3*noiseSig/kSize;
  F_thresh = 1.6;
  kSq = kSize^2;

  if color
    [M N C] = size( noisyImg );
  else
    [M N] = size( noisyImg );
  end

  deNoisedImg = noisyImg;

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
  parfor j=borderSize:M-borderSize
    for i=borderSize:N-borderSize
      % As far as I (Thomas) know, noisyImg can't be easily sliced to
      % improve performance. Instead, one would have to use spmd to do
      % such things. However, most of the time is spent in the two inner 
      % loops anyway 
      
      if color
        kernel = noisyImg( j-halfKSize:j+halfKSize, ...
          i-halfKSize:i+halfKSize, :);
        localWeights = zeros( searchSize, searchSize , 3);
        
        %TODO: Check if this is correct for color
        kernel_mean = mean(kernel(:));
        kernel_var = var(kernel(:));
      else
        kernel = noisyImg( j-halfKSize:j+halfKSize, ...
          i-halfKSize:i+halfKSize );
        localWeights = zeros( searchSize, searchSize );
        
        kernel_mean = mean(kernel(:));
        kernel_var = var(kernel(:));
      end
      
      %Approximate central weight (the weight where the Kernel is compared
      %to itself) with the best non central weight.
      max_weight = 0;

      %TODO: Do mean and variance (F) test 
      for jP=0:searchSize-1
        for iP=0:searchSize-1
          if (jP ~= halfSearchSize && iP ~= halfSearchSize)
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
            
            %Discard patches with too different mean or variance from
            %dictionary
            patch_mean = mean(v(:));
            
            if(abs(patch_mean - kernel_mean) > mean_thresh)
              localWeights( jP+1, iP+1 ,:) = 0;
            else
              patch_var = sum((v(:)-patch_mean).^2)/kSq;
              F = max(patch_var,kernel_var)/min(patch_var,kernel_var);
              if (F > F_thresh)
                localWeights( jP+1, iP+1 ,:) = 0;
              else
                distSq = ( kernel - v ) .* ( kernel - v );
                dist = sqrt(sum( distSq(:) )); %L2 distance

                %Non-vectorized Bayesian Non-Local means weights
                weight = exp( -0.5*(dist/noiseSig - bayes_dist_offset)^2 );
                localWeights( jP+1, iP+1 ,:) = weight;

                %Update max-weight
                max_weight = max(max_weight, weight);
              end
            end
          end
        end
      end
      
      %Set central weight
      if max_weight == 0
        localWeights(halfSearchSize + 1, halfSearchSize +1,:) = 1;
      else
        localWeights(halfSearchSize + 1, halfSearchSize +1,:) = max_weight;
      end
        
      if color
        localWeights = localWeights / sum( sum( localWeights(:,:,1) ) ); 
      else
        localWeights = localWeights / sum( localWeights(:) );
      end
      
      subImg = noisyImg( j-halfSearchSize : j+halfSearchSize, ...
          i-halfSearchSize : i+halfSearchSize, : );
      
      deNoisedImg(j,i,:) = sum( sum( localWeights .* subImg ) ) ;
      
    end

    ppm.increment(j);
  end
  
  
  %% clean up parallel
  try % use try / catch here, since delete(struct) will raise an error.
      delete(ppm);
  catch me %#ok<NASGU>
  end
  

  %% show output image
  imshow( deNoisedImg, [] );
  drawnow; % make sure it's displayed
  pause(0.01); % make sure it's displayed
  
  %% copy output images
  output = struct();
  output.deNoisedImg = deNoisedImg;
  output.prefix = 'NLM_';
  output.borderSize = borderSize;
