function output = deNoise2D_NLM_GW_gaussian_samp( noisyImg, config )
%Uses gaussian weighted L2 norm


kSize = config.kSize;
h = config.h;
noiseSig = config.noiseSig;
color = config.color;
halfKSize = floor( kSize/2 );
hSq = h*h;

a = 0.5*(kSize-1)/2;
searchPoints = config.searchPoints;
effectiveSearchWindow = config.effectiveSearchWindow;
aSearchWindow = 0.5*(effectiveSearchWindow-1)/2;

if color
    [M N C] = size( noisyImg );
    gaussKernel = fspecial('gaussian', kSize, a)*kSize^2;
    gaussKernel = repmat(gaussKernel, [1 1 3]);
else
    [M N] = size( noisyImg );
    %Define the gaussian kernel for the gaussian weighted L2-norm
    gaussKernel = fspecial('gaussian', kSize, a)*kSize^2;
end

deNoisedImg = noisyImg;

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
    for i=borderSize:N-borderSize
        % As far as I (Thomas) know, noisyImg can't be easily sliced to
        % improve performance. Instead, one would have to use spmd to do
        % such things. However, most of the time is spent in the two inner
        % loops anyway
        
        
        if color
            kernel = noisyImg( j-halfKSize:j+halfKSize, ...
                i-halfKSize:i+halfKSize, :);
            localWeights = zeros( searchPoints, 1 , 3);
        else
            kernel = noisyImg( j-halfKSize:j+halfKSize, ...
                i-halfKSize:i+halfKSize );
            localWeights = zeros( searchPoints, 1);
        end
        
        
        %generate searchPoints non-repeating pixel locations using gaussian
        %probability centered at j,i
        pointsToUse = round(normrnd(0,aSearchWindow, 2, searchPoints));
        pointsToUse(1,:) = pointsToUse(1,:) + j;
        if any(pointsToUse(1,:) < borderSize)
            pointsToUse(1, pointsToUse(1,:) < borderSize ) = borderSize;
        elseif any(pointsToUse(1,:) > M-borderSize)
            pointsToUse(1,pointsToUse(1,:) > M-borderSize) = M-borderSize;
        end
        
        pointsToUse(2,:) = pointsToUse(2,:) + i;
        if any(pointsToUse(2,:) < borderSize)
            pointsToUse(2, pointsToUse(2,:) < borderSize ) = borderSize;
        elseif any(pointsToUse(2,:) > N-borderSize)
            pointsToUse(2,pointsToUse(2,:) > N-borderSize) = N-borderSize;
        end
        
        %each column represents a new pixel location
        
        for k = 1:searchPoints
            
            vJ = pointsToUse(1, k);
            vI = pointsToUse(2, k);
            
            if color
                v = noisyImg( vJ-halfKSize : vJ+halfKSize, ...
                    vI-halfKSize : vI+halfKSize, : );
            else
                v = noisyImg( vJ-halfKSize : vJ+halfKSize, ...
                    vI-halfKSize : vI+halfKSize  );
            end
            
            %Gaussian weighted L2 norm squared
            distSq = ( kernel - v ) .* ( kernel - v );
            weightedDistSq = distSq.*gaussKernel;
            weightedDistSq = sum( weightedDistSq(:) );
            
            localWeights( k ,: ) = exp( - weightedDistSq / hSq );
            
        end
        
        
        denoisedSum = 0;
        if color
            localWeights = localWeights / sum( sum( localWeights(:,:,1) ) );
            for k=1:searchPoints
                vJ = pointsToUse(1, k);
                vI = pointsToUse(2, k);
                w = zeros(1,1,3);
                w(:) = localWeights(k,:);
                denoisedSum = denoisedSum + noisyImg(vJ, vI, :).*w;
            end
        else
            localWeights = localWeights / sum( localWeights(:) );
            for k=1:searchPoints
                vJ = pointsToUse(1, k);
                vI = pointsToUse(2, k);
                denoisedSum = denoisedSum + noisyImg(vJ, vI).*localWeights( k, :);
            end
        end
        
        deNoisedImg(j,i,:) = denoisedSum ;
        
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
output.prefix = 'NLM_GW_gaussian_samp';
output.borderSize = borderSize;