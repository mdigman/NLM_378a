
function data = loadMriImages( imgsDir )

  %imgsDir = '..\..\data\MRI\Series8_144_4CF9EA89.dcm_200';
  
  files = dir( imgsDir );
  files = files(3:end);
  nImgs = numel( files );

  img1 = dicomread( [imgsDir,'\',files(1).name] );
  sImg = size( img1 );

  data = zeros( sImg(1), sImg(2), nImgs-1 );
  data(:,:,1) = img1;
  
  for i=2:nImgs-1
    data(:,:,i) = dicomread( [imgsDir,'\',files(i).name] );
  end
  
end