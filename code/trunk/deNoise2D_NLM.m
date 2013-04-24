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

localWeights = zeros( searchSize, searchSize );

%Define the gaussian kernel for the gaussian weighted L2-norm
a = 0.5*(kSize-1)/2;
gaussKernel = fspecial('gaussian', kSize, a);

for j=borderSize:M-borderSize
    if mod(j,20)==0 disp(['Working on row ', num2str(j)]); end;
    
    for i=borderSize:N-borderSize
        %if mod(i,100)==0 disp(['Working on col ', num2str(i)]); end;
        
        kernel = noisyImg( j-halfKSize:j+halfKSize, ...
            i-halfKSize:i+halfKSize );
        
        for jP=0:searchSize-1
            for iP=0:searchSize-1
                %disp(['(jP,iP): (',num2str(jP),',',num2str(iP),')']);
                
                vJ = j-halfSearchSize+jP;
                vI = i-halfSearchSize+iP;
                v = noisyImg( vJ-halfKSize : vJ+halfKSize, ...
                    vI-halfKSize : vI+halfKSize  );
                
                distSq = ( kernel - v ) .* ( kernel - v );
                weightedDistSq = distSq.*gaussKernel;
                weightedDistSq = sum( weightedDistSq(:) ); %L2 norm squared
                
                localWeights( jP+1, iP+1 ) = exp( - weightedDistSq / hSq );
                
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

outputImages = struct();
outputImages.deNoisedImage = deNoisedImg;

outputPrefix = struct();
outputPrefix.deNoisedImage = 'NLM_';

end
