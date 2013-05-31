function output = deNoise2D_NLM_GW_euclidian( noisyImg, config )
%Uses gaussian weighted L2 norm


kSize = config.kSize;
searchSize = config.searchSize;
h = config.h;
noiseSig = config.noiseSig;
color = config.color;

halfSearchSize = floor( searchSize/2 );
halfKSize = floor( kSize/2 );
hSq = h*h;

hEuclidian = config.hEuclidian;
hSqEuclidian = hEuclidian^2;

a = 0.5*(kSize-1)/2;

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
for j=borderSize:M-borderSize
    for i=borderSize:N-borderSize
        % As far as I (Thomas) know, noisyImg can't be easily sliced to
        % improve performance. Instead, one would have to use spmd to do
        % such things. However, most of the time is spent in the two inner
        % loops anyway
        
        
        if color
            kernel = noisyImg( j-halfKSize:j+halfKSize, ...
                i-halfKSize:i+halfKSize, :);
            localWeights = zeros( searchSize, searchSize , 3);
        else
            kernel = noisyImg( j-halfKSize:j+halfKSize, ...
                i-halfKSize:i+halfKSize );
            localWeights = zeros( searchSize, searchSize );
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
                
                %Gaussian weighted L2 norm squared
                distSq = ( kernel - v ) .* ( kernel - v );
                weightedDistSq = distSq.*gaussKernel;
                weightedDistSq = sum( weightedDistSq(:) );
                
                %Euclidian distance scale inspired by bilateral filter
                weightedEuclidianDist = (j-vJ)^2 + (i-vI)^2;
                
                localWeights( jP+1, iP+1,: ) = exp( - weightedDistSq / hSq )*exp( - weightedEuclidianDist / hSqEuclidian );
                
            end
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
output.prefix = 'NLM_GW_euclidian_';
output.borderSize = borderSize;