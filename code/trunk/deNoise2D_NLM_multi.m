function output = deNoise2D_NLM_multi( noisyImg, config, origImg )
  % Initialize
  kSize = config.kSize;             % Similarity Window Size
  searchSize = config.searchSize;   % Search Window Size
  h = config.h;
  noiseSig = config.noiseSig;
  k = 80;                            % Number of Windows to look at
  
  % Zoom out by factor of 2
  noisyImgRect = zeros(floor(size(noisyImg,1)./2),size(noisyImg,2));
  noisyImgSmall = zeros(floor(size(noisyImg)./2));
  for j = 1:floor(size(noisyImg,1)./2)
      noisyImgRect(j,:) = noisyImg(2*j,:);
  end
  for i = 1:floor(size(noisyImg,2)./2)
      noisyImgSmall(:,i) = noisyImgRect(:,2*i);
  end

%   noisyImgSmall = impyramid(noisyImg,'reduce');

  % Apply NLM to zoomed out Image
  similarities = deNoise2D_multi_whole_image(noisyImgSmall,k,kSize,2*searchSize,h);
  
  halfSearchSize = floor( searchSize/2 );
  halfKSize = floor( kSize/2 );
  hSq = h*h;

  [M N] = size( noisyImg );

  deNoisedImg = noisyImg;

  borderSize = halfKSize+halfSearchSize+1;

  for j = borderSize:M-borderSize
      if mod(j,10)==0 disp(['Working on row ', num2str(j)]); end;
      
      for i = borderSize:N-borderSize
          % Only Perform NLM if similarity windows exist
          if (similarities(floor(j/2),floor(i/2),1,1) ~= 0)
              kernel = noisyImg(j-halfKSize:j+halfKSize, ...
                                i-halfKSize:i+halfKSize);
              % Initialize Weights, Windows
              weights = zeros(3, 3, k);
              subImg = zeros(3, 3, k);
              % Compute Weights about each similarity pixel
              for p = 1:k
                  % Get index of similar patch
                  col_ind = similarities(floor(j/2),floor(i/2),p,1);
                  row_ind = similarities(floor(j/2),floor(i/2),p,2);
                  % Get window about similar patch
                  similarWindow = noisyImg(2*row_ind-halfKSize-1:2*row_ind+halfKSize+1, ...
                                           2*col_ind-halfKSize-1:2*col_ind+halfKSize+1);
                  % Compute weights for each patch
                  for jP=-1:1
                      for iP=-1:1
                          distSq = (kernel - similarWindow(jP+2:jP+2*halfKSize+2, iP+2:iP+2*halfKSize+2)) ...
                                 .*(kernel - similarWindow(jP+2:jP+2*halfKSize+2, iP+2:iP+2*halfKSize+2));
                          distSq = sum( distSq(:)); % L2 Norm Squared
                          
                          weights(jP+2,iP+2,p) = exp( - distSq / hSq );
                      end
                  end
          
                  subImg(:,:,p) = noisyImg(2*row_ind-1:2*row_ind+1, ...
                                           2*col_ind-1:2*col_ind+1);
              end
              weights = weights./ sum(weights(:));
              deNoisedImg(j,i) = sum(sum(sum(weights.*subImg)));
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
    output.mse = calculateMSE( origImg, deNoisedImg, 2*borderSize );
  else
  end
end
  
  
function similarities = deNoise2D_multi_whole_image(noisyImg,k,kSize,searchSize,h)
  % Initialize
  halfKSize = floor( kSize/2 );
  halfSearchSize = floor( searchSize/2 );
  hSq = h*h;

  [M N] = size( noisyImg );

  borderSize = halfKSize+halfSearchSize+1;
  similarities = zeros(M,N,k,2);    % Captures k most similar patches

  for j=borderSize:M-borderSize
    if mod(j,10)==0 disp(['Working on row ', num2str(j)]); end;

    for i=borderSize:N-borderSize
      weights = zeros(searchSize,searchSize);
      kernel = noisyImg( j-halfKSize:j+halfKSize, ...
        i-halfKSize:i+halfKSize );

      for jP=0:searchSize-1
        for iP=0:searchSize-1
          vJ = j-halfSearchSize+jP;
          vI = i-halfSearchSize+iP;
          %if ((j ~= vJ) || (i ~= vI))
              v = noisyImg( vJ-halfKSize : vJ+halfKSize, ...
                  vI-halfKSize : vI+halfKSize  );
              
              distSq = ( kernel - v ) .* ( kernel - v );
              distSq = sum( distSq(:) ); %L2 norm squared
              
              weights( jP+1, iP+1 ) = exp( - distSq / hSq );
          %end
        end
      end

      weights = weights ./ sum( weights(:) );
      % Calculate indices of k largest weights
      similarities(j,i,:,:) = largestWeights(weights,j,i,k);
    end
  end
end
  
function kWeights = largestWeights(weights,row_ind,col_ind,k)
    halfSearchSize = floor(size(weights,1)/2);
    kWeights = zeros(1,1,k,2);
    weightsLeft = k;
    while (weightsLeft > 0)
        % Find max weight
        maxWeight = max(max(weights));
        % Get index of max weight
        [row,col] = find(weights == maxWeight,weightsLeft);
        % Convert Indices to Absolute Position
        row_abs = row + row_ind-halfSearchSize-1;
        col_abs = col + col_ind-halfSearchSize-1;
        kWeights(1,1,k-weightsLeft+1:k-weightsLeft+length(row),:) = [row_abs,col_abs];
        % Adjust number of weights to find
        weightsLeft = weightsLeft - length(row);
        % Set Max Weight to 0
        for i = 1:length(row)
            weights(row(i),col(i)) = 0;
        end
    end
end
