function output = deNoise2D_NLM_KLDivPrior( noisyImg, config )

kSize = config.kSize;
kSq = kSize^2;
searchSize = config.searchSize;
h = config.h;
noiseSig = config.noiseSig;
color = config.color;

KLh = config.KLh;
KLexp = config.KLexp;

halfSearchSize = floor( searchSize/2 );
halfKSize = floor( kSize/2 );
hSq = h*h;

if color
    [M N C] = size( noisyImg );
else
    [M N] = size( noisyImg );
end

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

%Calculate histogram for each of the patches
empPatchPmfs = cell(M,N);

parfor j=halfKSize+1:M-halfKSize-1
    for i=halfKSize+1:N-halfKSize-1
      patch = noisyImg( j-halfKSize:j+halfKSize, ...
                i-halfKSize:i+halfKSize );
      empPatchPmfs{j,i} = histc(patch(:),(0:1/255:1))/kSq;       
    end
end

%-- perform algorithm
parfor j=borderSize:M-borderSize
    for i=borderSize:N-borderSize
        
      KLDivs = zeros( searchSize, searchSize);
      empPmfKernel = empPatchPmfs{j,i};
      
        if color
            kernel = noisyImg( j-halfKSize:j+halfKSize, ...
                i-halfKSize:i+halfKSize, :);
            distSqs = zeros( searchSize, searchSize , 3);
        else
            kernel = noisyImg( j-halfKSize:j+halfKSize, ...
                i-halfKSize:i+halfKSize );
            distSqs = zeros( searchSize, searchSize);
            
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
                
                %L2 norm squared
                distSq = ( kernel - v ) .* ( kernel - v );
                distSqs( jP+1, iP+1,: ) = sum( distSq(:) );
                
                %KL-divergence
                empPmf = empPatchPmfs{vJ,vI};
                sup = find(empPmf > 1e-12 & empPmfKernel > 1e-12);
                KLDivs( jP+1, iP+1,: ) = sum(empPmfKernel(sup).*...
                  log2(empPmfKernel(sup)./empPmf(sup)));
                
            end
        end
        KLDivs = exp( -(KLDivs.^KLexp)/KLh);
        KLDivs = KLDivs/sum(KLDivs(:));
        localWeights = exp( - distSqs / hSq );
        
        if color
            localWeights = localWeights / sum( sum( localWeights(:,:,1) ) );
            KLDivs = repmat(KLDivs,[1 3]);
        else
            localWeights = localWeights / sum( localWeights(:) );
        end
        
        subImg = noisyImg( j-halfSearchSize : j+halfSearchSize, ...
            i-halfSearchSize : i+halfSearchSize, : );
        
        deNoisedImg(j,i,:) = sum( sum(KLDivs.* localWeights .* subImg ) ) ;
        
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


%-- show output image
%imshow( deNoisedImg, [] );
drawnow; % make sure it's displayed
pause(0.01); % make sure it's displayed

%-- copy output images
output = struct();
output.deNoisedImg = deNoisedImg;
output.prefix = 'NLM_';
output.borderSize = borderSize;