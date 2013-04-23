
function deNoisedImg = deNoise2D_NLM( noisyImg, noiseSig )

  kSize = 7;
  searchSize = 7;
  searchSize = 21;
  h = 10*noiseSig;

  halfSearchSize = floor( searchSize/2 );
  halfKSize = floor( kSize/2 );
  hSq = h*h;
  
  [M N] = size( noisyImg );
  nPix = M*N;

  deNoisedImg = noisyImg;

  borderSize = halfKSize+halfSearchSize+1;

  localWeights = zeros( searchSize, searchSize );

  for j=borderSize:M-borderSize
    if mod(j,20)==0 disp(['Working on row ', num2str(j)]); end;

    for i=borderSize:N-borderSize
      %if mod(i,100)==0 disp(['Working on col ', num2str(i)]); end;

      kernel = noisyImg( j-halfKSize:j+halfKSize, ...
                         i-halfKSize:i+halfKSize );
      stdK = std( kernel(:) );

      for jP=0:searchSize-1
        for iP=0:searchSize-1
          %disp(['(jP,iP): (',num2str(jP),',',num2str(iP),')']);
          
          vJ = j-halfSearchSize+jP;
          vI = i-halfSearchSize+iP;
          v = noisyImg( vJ-halfKSize : vJ+halfKSize, ...
                        vI-halfKSize : vI+halfKSize  );

          distSq = ( kernel - v ) .* ( kernel - v );
          distSq = sum( distSq(:) );

          localWeights( jP+1, iP+1 ) = exp( - distSq / hSq );

        end
      end

      localWeights = localWeights / sum( localWeights(:) );

      subImg = noisyImg( j-halfSearchSize : j+halfSearchSize, ...
                         i-halfSearchSize : i+halfSearchSize );

      deNoisedImg(j,i) = sum( sum( localWeights .* subImg ) );
    end
     
    if mod(j,50)==0 imshow( deNoisedImg, [] ); end;
    drawnow;
  end

end
