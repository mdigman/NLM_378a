function test_suite_unix( algorithmHandle, config )
inDir = '../../data/images';

% TEST SUITE
noiseSig = config.noiseSig; %standard deviation!
noiseMean = config.noiseMean;

files = strsplit(ls(inDir),' '); %Put each name into cell array
%files = files(3:end);

sFiles = size(files);
nFiles = sFiles(2);

dateTime = datestr(now);
dateTime = strrep(dateTime, ':', '');
dateTime = strrep(dateTime, '-', '');
dateTime = strrep(dateTime, ' ', '_');
outDir = ['output_',dateTime];
mkdir(outDir);

logID = fopen([outDir,'/log.txt'], 'w');

for i=1:nFiles
    imgFile = files{i};
    img = imread( [inDir,'/',imgFile] );
    
    nDimsImg = ndims( img );
    if nDimsImg>2
        img = rgb2gray( img );
    end
    
    img = double( img )/255.;
    
    sImg = size( img );
    noise = normrnd( noiseMean, noiseSig, sImg(1), sImg(2) );
    noisyImg = img + noise;
    imwrite( noisyImg, [outDir,'/noisy_',imgFile] );
    
    tic
    [outputImages, outputPrefix] = algorithmHandle(noisyImg, config);
    runtime = toc;

    outputFields = fields(outputImages);
    for i=1:length(outputFields)
        imwrite( outputImages.(outputFields{i}), [outDir, '/', outputPrefix.(outputFields{i}), imgFile] );
    end
    fprintf( logID, '%s runtime (sec): %f\n', imgFile, runtime );
end

fclose(logID);

end