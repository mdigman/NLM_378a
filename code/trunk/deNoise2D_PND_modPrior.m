function output = deNoise2D_PND_modPrior( noisyImg, config )

[height,width] = size(noisyImg);
kernel_edge = 7;
window_edge = 21;
half_kernel = floor(kernel_edge/2);
half_window = floor(window_edge/2);

% ----- Initialize for Prior Computation ------
color = config.color;
hEuclidian = config.hEuclidian;
hSqEuclidian = hEuclidian^2;

lambda = 1;

eucDistsSq =  ones(window_edge,1)*((1:window_edge) -ceil(window_edge/2));
eucDistsSq = eucDistsSq.^2 + (eucDistsSq').^2;

a = 0.5*(kernel_edge-1)/2;
if color
    gaussKernel = fspecial('gaussian', kernel_edge, a)*kernel_edge^2;
    gaussKernel = repmat(gaussKernel, [1 1 3]);
else
    gaussKernel = fspecial('gaussian', kernel_edge, a)*kernel_edge^2;
end

smoothedImg = imfilter(noisyImg, gaussKernel, 'replicate');
% ----- Initialize for Prior Computation ------

% Pick Random Subsample of Pixels (num_img_pixels/10 pixels)
num_img_pixels = height*width;
corner_pixels = half_kernel*half_kernel;
side_pixels = half_kernel*(height-2*half_kernel);
top_pixels = half_kernel*(width-2*half_kernel);
num_border_pixels = 4*corner_pixels + 2*side_pixels + 2*top_pixels;
num_pixels = num_img_pixels - num_border_pixels;

rand_ind = randi([1,num_pixels],[num_img_pixels/10,1]);
[y,x] = ind2sub([height-2*half_kernel,width-2*half_kernel],rand_ind);
y = y + half_kernel;
x = x + half_kernel;
psi = [y,x];


% -----------PCA-------------
% Collect Randomly selected Neighborhoods
N = size(psi,1);
neighborhoods = zeros(kernel_edge^2,N);
for i = 1:N
%     neighborhoods(:,i) = vec(noisyImg(psi(i,1)-half_kernel:psi(i,1)+half_kernel, ...
%                                       psi(i,2)-half_kernel:psi(i,2)+half_kernel));
    tmp_nhoods = noisyImg(psi(i,1)-half_kernel:psi(i,1)+half_kernel, ...
                          psi(i,2)-half_kernel:psi(i,2)+half_kernel);
    neighborhoods(:,i) = tmp_nhoods(:);
end

% Perform PCA on Randomly Selected Neighborhoods
M = kernel_edge^2;
[eig_vec,eig_val] = deNoise2D_PND_PCA(neighborhoods);

% % Show top 6 neighborhoods
% figure(1)
% for i = 1:6
%     subplot(2,3,i);
%     imshow(reshape(eig_vec(:,end-i+1),kernel_edge,kernel_edge));
%     title(i)
% end

% Capture Smallest Eigenvalue
sigma_hat = sqrt(eig_val(1,1));

% -----------Parallel Analysis-------------
d = deNoise2D_PND_parallel(neighborhoods,eig_val);


% Use only the d largest eigenvectors as our space
b = eig_vec(:,end:-1:end-5);

% Estimate h
m = 2.84;
c = 13.81/256;
h = m*sigma_hat+c;

% Project all neighborhoods into the d-dimensional subspace
all_nhoods = zeros(height-2*half_kernel,width-2*half_kernel,d);
for i = half_kernel+1:height-half_kernel
    if(mod(i,50) == 0); fprintf('Projecting Row %d...\n',i); end
    for j = half_kernel+1:width-half_kernel
%         all_nhoods(i,j,:) = b'*vec(noisyImg(i-half_kernel:i+half_kernel, ...
%                                             j-half_kernel:j+half_kernel));
        tmp_noisyImg = noisyImg(i-half_kernel:i+half_kernel, ...
                                j-half_kernel:j+half_kernel);
        all_nhoods(i,j,:) = b'*tmp_noisyImg(:);
    end
end

% Do NLM
fprintf('Doing NLM\n')
deNoisedImg = noisyImg;
for i = half_window+half_kernel+1:height-half_window-half_kernel
    if(mod(i,10) == 0); fprintf('Denoising Row %d...\n',i);end
    for j = half_window+half_kernel+1:width-half_window-half_kernel
        % --------- Compute Prior Distribution --------
        if color
            corrKer = smoothedImg( i-half_kernel:i+half_kernel, ...
                                   j-half_kernel:j+half_kernel, :);
            corrSearch = smoothedImg( i-half_window:i+half_window, ...
                                      j-half_window:j+half_window, : );
            C1 = normxcorr2(corrKer(:,:,1), corrSearch(:,:,1) );
            C2 = normxcorr2(corrKer(:,:,2), corrSearch(:,:,2) );
            C3 = normxcorr2(corrKer(:,:,3), corrSearch(:,:,3) );
            C = ( C1 + C2 + C3 ) / 3;
        else
            corrKer = smoothedImg( i-half_kernel:i+half_kernel, ...
                                   j-half_kernel:j+half_kernel);
            corrSearch = smoothedImg( i-half_window:i+half_window, ...
                                      j-half_window:j+half_window );
            C = normxcorr2(corrKer, corrSearch);
        end
        C = C( half_kernel+1:end-half_kernel, half_kernel+1:end-half_kernel );
        
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
        prior = (C + exp( -( lambda * varKer) ) * (1-C)).* ...
                  exp( - eucDistsSq / hSqEuclidian );
        % -------- Compute Prior Distribution ---------------
        
        % Get center neighborhood
        center = reshape(all_nhoods(i,j,:),d,1);
        % Get weights
        weights = zeros(window_edge,window_edge);
        for k = -half_window:half_window
            for l = -half_window:half_window
                f_d = reshape(all_nhoods(i+k,j+l,:),d,1);
                weights(k+half_window+1,l+half_window+1) = ...
                                            exp(-norm(center-f_d,2)^2/h^2);
            end
        end
        % Compute Weights with Prior
        weights = weights.*prior;
        % Normalize weights
        weights = 1/(sum(weights(:))).*weights;
        % Estimate Pixel
        u_tmp = noisyImg(i-half_window:i+half_window,j-half_window:j+half_window) ...
                .*weights;
        deNoisedImg(i,j) = sum(u_tmp(:));
    end
end

%-- show output image
imshow( deNoisedImg, [] );
drawnow; % make sure it's displayed
pause(0.01); % make sure it's displayed


borderSize = half_kernel+half_window+1;
%-- copy output images
output = struct();
output.deNoisedImg = deNoisedImg;
output.prefix = 'NLM_';
output.borderSize = borderSize;