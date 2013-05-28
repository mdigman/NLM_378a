function output = deNoiseMRI_NLM( noisyMRI, config )

  kSize = config.kSize;
  searchSize = config.searchSize;
  h = config.h;
  noiseSig = config.noiseSig;

  halfSearchSize = floor( searchSize/2 );
  halfKSize = floor( kSize/2 );
  hSq = h*h;

  [K M N] = size( noisyMRI );

  deNoisedMRI = noisyMRI;

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
        localWeights = zeros( searchSize, searchSize, searchSize );

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
              distSq = sum( distSq(:) ); %L2 norm squared

              localWeights( kP+1, jP+1, iP+1 ) = distSq;
            end
          end
        end

        localWeights = exp( -localWeights / hSq );
        localWeights = localWeights / sum( localWeights(:) );

        subMRI = noisyMRI( k-halfSearchSize : k+halfSearchSize, ...
            j-halfSearchSize : j+halfSearchSize, ...
            i-halfSearchSize : i+halfSearchSize, : );

        deNoisedMRI(k,j,i) = sum( localWeights(:) .* subMRI(:) );
      end

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
  output.prefix = 'NLM_';
  output.borderSize = borderSize;
end
