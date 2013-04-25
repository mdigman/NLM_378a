function [outputImages outputPrefix] = deNoise2D_NLM( noisyImg, config )

kSize = config.kSize;
searchSize = config.searchSize;
h = config.h;
noiseSig = config.noiseSig;

halfSearchSize = floor( searchSize/2 );
halfKSize = floor( kSize/2 );
hSq = h*h;

[M N] = size( noisyImg );
nPix = M*N;

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

parfor j=borderSize:M-borderSize
    for i=borderSize:N-borderSize    
        % As far as I (Thomas) know, noisyImg can't be easily sliced to
        % improve performance. Instead, one would have to use spmd to do
        % such things. However, most of the time is spent in the two inner 
        % loops anyway    
        kernel = noisyImg( j-halfKSize:j+halfKSize, ...
            i-halfKSize:i+halfKSize );
        
        localWeights = zeros( searchSize, searchSize );
        
        for jP=0:searchSize-1
            for iP=0:searchSize-1
                %disp(['(jP,iP): (',num2str(jP),',',num2str(iP),')']);
                
                vJ = j-halfSearchSize+(jP);
                vI = i-halfSearchSize+(iP);
                v = noisyImg( vJ-halfKSize : vJ+halfKSize, ...
                    vI-halfKSize : vI+halfKSize);
                
                distSq = ( kernel - v ) .* ( kernel - v );
                distSq = sum( distSq(:) ); %L2 norm squared
                
                localWeights( jP+1, iP+1 ) = exp( - distSq / hSq );
                
            end
        end
        
        localWeights = localWeights / sum( localWeights(:) );
        
        subImg = noisyImg( j-halfSearchSize : j+halfSearchSize, ...
            i-halfSearchSize : i+halfSearchSize );
        
        deNoisedImg(j,i) = sum( sum( localWeights .* subImg ) );
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

outputImages = struct();
outputImages.deNoisedImage = deNoisedImg;

outputPrefix = struct();
outputPrefix.deNoisedImage = 'NLM_';

end
