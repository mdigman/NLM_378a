function output = deNoise2D_NLM_stationary_fix(noisyImg, config, origImg)

kSize = config.kSize;
searchSize = config.searchSize;
h = config.h;
varianceCutoff = config.varianceCutoff;
noiseSig = config.noiseSig;

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
        NLestimatedU = sum( sum( localWeights .* subImg ) );
        NLestimatedUSq = sum( sum( localWeights .* (subImg.^2) ) );
        NLestimatedSigmaSq = NLestimatedUSq - NLestimatedU.^2;
        
        sigmaSqMetric = NLestimatedSigmaSq;
        if sigmaSqMetric > varianceCutoff
            %disp(['Detected high sigma of ', num2str(sigmaSqMetric), ' at pixel ', num2str(j), ', ' num2str(i)]);
            deNoisedImg(j,i) = NLestimatedU + max((sigmaSqMetric - noiseSig^2)/sigmaSqMetric, 0)*(noisyImg(j,i)-NLestimatedU);
        else
            %disp(['Detected low sigma of ', num2str(sigmaSqMetric), ' at pixel ', num2str(j), ', ' num2str(i)]);
            deNoisedImg(j,i) = NLestimatedU;
        end
    end
    
    if mod(j,50)==0 imshow( deNoisedImg, [] ); end;
    drawnow;
end

output = struct();
output.deNoisedImg = deNoisedImg;
output.prefix = 'NLM_stat_fix_';

output.mse = -1;
if nargin > 2
  output.mse = calculateMSE( origImg, deNoisedImg, borderSize );
else

end
