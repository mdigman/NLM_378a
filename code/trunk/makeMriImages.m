
function makeMriImages( filename )

  %filename = '..\..\..\MRI_Results\eucNLMwModPriorPlus_deNoisedMRI.mat';
  %filename = '..\..\..\MRI_Results\NLM_deNoisedMRI.mat';
  filename = '..\..\..\MRI_Results\NLM_wPriorMod_deNoisedMRI.mat';
  
  if ~exist( filename, 'file' )
    error( 'filename does not exist' );
  end

  filenameParts = strsplit( filename, '.' );

  dir = sprintf('%s.' ,filenameParts{1:end-1});
  dir = dir(1:end-1);
  mkdir( dir );
  dirParts = strsplit( dir, '\' );
  
  load(filename);

  sData = size( subDeNoised );

  deNoisedNorm = subDeNoised / max( subNoisyData(:) );
  noisyNorm = subNoisyData / max( subNoisyData(:) );
  
  for i=14+1:sData(1)-14
    outFile = [ dir, '\deNoised_', dirParts{end}, '_', num2str(i), '.jpg' ];
    imwrite(squeeze(deNoisedNorm(i,:,:)), outFile, 'jpg' );
    outFile = [ dir, '\noisy_', dirParts{end}, '_', num2str(i), '.jpg' ];
    imwrite(squeeze(noisyNorm(i,:,:)), outFile, 'jpg' );
  end
  
end

