function output = deNoise2D_NLM_GW_modPrior( noisyImg, config )
%-- Uses gaussian weighted L2 norm

kSize = config.kSize;
searchSize = config.searchSize;
h = config.h;
hSq = h^2;
noiseSig = config.noiseSig;
color = config.color;

lambda = 1;

halfSearchSize = floor( searchSize/2 );
halfKSize = floor( kSize/2 );

a = 0.5*(kSize-1)/2;
if color
    [M N C] = size( noisyImg );
    gaussKernel = fspecial('gaussian', kSize, a)*kSize^2;
    gaussKernel = repmat(gaussKernel, [1 1 3]);
else
    [M N] = size( noisyImg );
    gaussKernel = fspecial('gaussian', kSize, a)*kSize^2;
end

smoothedImg = imfilter(noisyImg, gaussKernel, 'replicate');
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


%-- perform algorithm
parfor j=borderSize:M-borderSize
    for i=borderSize:N-borderSize
        
        halfCorrSearchSize = halfSearchSize+halfKSize;
        if color
            kernel = noisyImg( j-halfKSize:j+halfKSize, ...
                i-halfKSize:i+halfKSize, :);
            corrKer = smoothedImg( j-halfKSize:j+halfKSize, ...
                i-halfKSize:i+halfKSize, :);
            corrSearch = smoothedImg( j-halfCorrSearchSize:j+halfCorrSearchSize, ...
                i-halfCorrSearchSize:i+halfCorrSearchSize, : );
            localWeights = zeros( searchSize, searchSize , 3);
            C1 = normxcorr2(corrKer(:,:,1), corrSearch(:,:,1) );
            C2 = normxcorr2(corrKer(:,:,2), corrSearch(:,:,2) );
            C3 = normxcorr2(corrKer(:,:,3), corrSearch(:,:,3) );
            C = ( C1 + C2 + C3 ) / 3;
        else
            kernel = noisyImg( j-halfKSize:j+halfKSize, ...
                i-halfKSize:i+halfKSize );
            corrKer = smoothedImg( j-halfKSize:j+halfKSize, ...
                i-halfKSize:i+halfKSize);
            corrSearch = smoothedImg( j-halfCorrSearchSize:j+halfCorrSearchSize, ...
                i-halfCorrSearchSize:i+halfCorrSearchSize );
            localWeights = zeros( searchSize, searchSize );
            C = normxcorr2(corrKer, corrSearch);
        end
        C = C( 2*halfKSize+1:end-2*halfKSize, 2*halfKSize+1:end-2*halfKSize );
        
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
                localWeights( jP+1, iP+1 ,:) = sum( weightedDistSq(:) );
                
            end
        end
        
        localWeights = exp( -localWeights/hSq );
        
        C = max( C, 0 );
        if color
            tmp = corrKer(:,:,1);
            varKer1 = var( tmp(:) );
            tmp = corrKer(:,:,2);
            varKer2 = var( tmp(:) );
            tmp = corrKer(:,:,3);
            varKer3 = var( tmp(:) );
            varKer = ( varKer1 + varKer2 + varKer3 ) / 3;
        else
            varKer = var( corrKer(:) );
        end
        prior = C + exp( -( lambda * varKer) ) * (1-C);
        prior = prior / ( sum(sum(prior)));
        if color
            localWeights(:,:,1) = localWeights(:,:,1) .* prior;
            localWeights(:,:,2) = localWeights(:,:,1);
            localWeights(:,:,3) = localWeights(:,:,1);
            localWeights = localWeights / sum( sum( localWeights(:,:,1) ) );
        else
            localWeights = localWeights .* prior;
            localWeights = localWeights / sum( localWeights(:) );
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
output.prefix = 'NLM_GW_modPrior_';
output.borderSize = borderSize;