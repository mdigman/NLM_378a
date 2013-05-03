function test_suite( algorithmHandle, config )
% CRITICAL CONFIG CHECK
% if not present write default
testSuiteAddNoise = true;
if any(strcmp(fields(config), 'testSuiteAddNoise'))
    testSuiteAddNoise = config.testSuiteAddNoise;
end
testSuiteUseImages = {};
if any(strcmp(fields(config), 'testSuiteUseImages'))
    testSuiteUseImages = config.testSuiteUseImages;
end
testSuiteUseExternalImage = false; %note: testSuiteExternalImage MUST be present
testSuiteExternalImage = [];
if any(strcmp(fields(config), 'testSuiteUseExternalImage')) && ... 
   any(strcmp(fields(config), 'testSuiteExternalImage'))
    testSuiteUseExternalImage = config.testSuiteUseExternalImage;
    testSuiteExternalImage = config.testSuiteExternalImage;
end

% FILE SETUP
% by default uses all images, change config.testSuiteUseImages to pick
% individual files
if isunix
    fileSepChar = '/';
    inDir = ['../../data/images'];
else
    fileSepChar = '\';
    inDir = ['..\..\data\images'];
end

if testSuiteUseExternalImage
    nFiles = 1;
elseif isunix
    if isempty(testSuiteUseImages)
        files = strsplit(ls(inDir),' '); %Put each name into cell array
        sFiles = size(files);
        nFiles = sFiles(2);
    else
        nFiles = numel(testSuiteUseImages);
        files = testSuiteUseImages;
    end
else
    if isempty(testSuiteUseImages)
        files = ls(inDir);
        files = files(3:end,:);
        sFiles = size(files);
        nFiles = sFiles(1);
    else
        nFiles = numel(testSuiteUseImages);
        files = testSuiteUseImages;
    end
end

% EXTRACT NECESSARY CONFIG INFORMATION
noiseSig = config.noiseSig; %standard deviation
noiseMean = config.noiseMean;

dateTime = datestr(now);
dateTime = strrep(dateTime, ':', '');
dateTime = strrep(dateTime, '-', '');
dateTime = strrep(dateTime, ' ', '_');
outDir = ['output_',dateTime];
mkdir(outDir);

if testSuiteUseExternalImage
    imwrite(testSuiteExternalImage, [outDir,fileSepChar,'external_image.png']); 
else
    callSeq = dbstack();
    nCallSeq = numel( callSeq );
    runFile = callSeq( nCallSeq ).file;
    copyfile( runFile, [outDir,fileSepChar,runFile] );    
end


% RECORD CONFIG FOR FUTURE REFERENCE
configID = fopen([outDir,fileSepChar,'config.txt'], 'w');
fieldNames = fields(config);
for i=1:numel(fieldNames)
    fprintf( configID, '%s: ', fieldNames{i});
    allValues = config.(fieldNames{i});
    if ~strcmp(fieldNames{i}, 'testSuiteExternalImage')
        for j=1:numel(allValues)
            if iscell(allValues(j))
                fprintf( configID, '%f, ', allValues{j});
            else
                fprintf( configID, '%f, ', allValues(j));
            end
        end
    end
    fprintf(configID, '\n');
end
fclose(configID);

% OPEN FILES FOR WRITING
logID = fopen([outDir,fileSepChar,'log.csv'], 'w');
fprintf( logID, 'filename, runtime (sec), MSE, Paper MSE\n');

% PROCESS EACH FILE
for i=1:nFiles
    if testSuiteUseExternalImage
        img = testSuiteExternalImage;
        imgFile = 'external_image.png';
    else
        if ~isempty(testSuiteUseImages)
            imgFile = files{i};
        elseif isunix
            imgFile = files{i};
        else
            imgFile = strtrim( files(i,:) );
        end
        img = imread( [inDir,fileSepChar,imgFile] );
    end
    
    nDimsImg = ndims( img );
    if nDimsImg>2
        img = rgb2gray( img );
    end
    
    img = double( img )/255.;
    
    sImg = size( img );
    if testSuiteAddNoise
        noise = normrnd( noiseMean, noiseSig, sImg(1), sImg(2) );
        noisyImg = img + noise;
    else
        noisyImg = img;
    end
    imwrite( noisyImg, [outDir,fileSepChar,'noisy_',imgFile] );
    
    tic
    output = algorithmHandle(noisyImg, config, img);
    runtime = toc;
    
    imwrite( output.deNoisedImg, [outDir, fileSepChar, ...
        output.prefix, imgFile] );
    
    magDiffImg = abs( img - output.deNoisedImg );
    imwrite( magDiffImg, [outDir, fileSepChar, output.prefix, ...
        '_diff_',imgFile] );
    
    fprintf( logID, '%s, %f, %f, %f\n', imgFile, runtime, output.mse, output.mse*255^2 );
end

fclose(logID);

end
