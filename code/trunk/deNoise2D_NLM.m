function output = deNoise2D_NLM( noisyImg, config, origImg )

  kSize = config.kSize;
  searchSize = config.searchSize;
  h = config.h;
  noiseSig = config.noiseSig;
  color = config.color;

  halfSearchSize = floor( searchSize/2 );
  halfKSize = floor( kSize/2 );
  hSq = h*h;

  if color
    [M N C] = size( noisyImg );
  else
    [M N] = size( noisyImg );
  end 
  nPix = M*N;
  
  deNoisedImg = noisyImg;

  borderSize = halfKSize+halfSearchSize+1;

  if color
    localWeights = zeros( searchSize, searchSize , 3);
  else
    localWeights = zeros( searchSize, searchSize );
  end

  for j=borderSize:M-borderSize
    if mod(j,10)==0 disp(['Working on row ', num2str(j)]); end;

    for i=borderSize:N-borderSize
      %if mod(i,100)==0 disp(['Working on col ', num2str(i)]); end;

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
          distSq = sum( distSq(:) ); %L2 norm squared

          localWeights( jP+1, iP+1 ,:) = exp( - distSq / hSq );
        end
      end

      if color
        localWeights = localWeights / sum( sum( localWeights(:,:,1) ) ); 
      else
        localWeights = localWeights / sum( localWeights(:) );
      end
      
      if color
        subImg = noisyImg( j-halfSearchSize : j+halfSearchSize, ...
          i-halfSearchSize : i+halfSearchSize, : );
      else
        subImg = noisyImg( j-halfSearchSize : j+halfSearchSize, ...
          i-halfSearchSize : i+halfSearchSize );
      end
      
      if color
        deNoisedImg(j,i,:) = sum( sum( localWeights .* subImg ) ) ;;
      else
        deNoisedImg(j,i) = sum( sum( localWeights .* subImg ) );
      end
    end

    if mod(j,50)==0 imshow( deNoisedImg, [] ); end;
    drawnow;
  end
  
  output = struct();
  output.deNoisedImg = deNoisedImg;
  output.prefix = 'NLM_';

  output.mse = -1;
  if nargin > 2
    output.mse = calculateMSE( origImg, deNoisedImg, borderSize );
  else
  end
end
