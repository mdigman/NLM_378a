function test_suite( algorithmHandle, config )
inDir = '..\..\data\images';

% Add path for parallel progress tracking
addpath('./matlab-ParforProgress2')

% TEST SUITE
noiseSig = config.noiseSig; %standard deviation!
noiseMean = config.noiseMean;

files = ls(inDir);
files = files(3:end,:);

sFiles = size(files);
nFiles = sFiles(1);

dateTime = datestr(now);
dateTime = strrep(dateTime, ':', '');
dateTime = strrep(dateTime, '-', '');
dateTime = strrep(dateTime, ' ', '_');
outDir = ['output_',dateTime];
mkdir(outDir);

logID = fopen([outDir,'\log.txt'], 'w');

for i=1:nFiles
    imgFile = strtrim( files(i,:) );
    img = imread( [inDir,'\',imgFile] );
    
    nDimsImg = ndims( img );
    if nDimsImg>2
        img = rgb2gray( img );
    end
    
    img = double( img )/255.;
    
    sImg = size( img );
    noise = normrnd( noiseMean, noiseSig, sImg(1), sImg(2) );
    noisyImg = img + noise;
    imwrite( noisyImg, [outDir,'\noisy_',imgFile] );
    
    config.fileName = imgFile;
    
    tic
    [outputImages, outputPrefix] = algorithmHandle(noisyImg, config);
    runtime = toc;

    outputFields = fields(outputImages);
    for i=1:length(outputFields)
        imwrite( outputImages.(outputFields{i}), [outDir, '\', outputPrefix.(outputFields{i}), imgFile] );
    end
    fprintf( logID, '%s runtime (sec): %f\n', imgFile, runtime );
end

fclose(logID);

end