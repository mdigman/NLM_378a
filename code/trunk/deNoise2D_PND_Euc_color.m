function output = deNoise2D_PND_Euc_color( noisyImg, config )

[height,width,chan] = size(noisyImg);
kernel_edge = 7;
window_edge = 21;
half_kernel = floor(kernel_edge/2);
half_window = floor(window_edge/2);
sigma = config.noiseSig;

% ----- Initialize for Prior Computation ------
color = config.color;
hEuclidian = config.hEuclidian;
hSqEuclidian = hEuclidian^2;

eucDistsSq =  ones(window_edge,1)*((1:window_edge) -ceil(window_edge/2));
eucDistsSq = eucDistsSq.^2 + (eucDistsSq').^2;

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
neighborhoods = zeros(chan*kernel_edge^2,N);
parfor i = 1:N
%     neighborhoods(:,i) = vec(noisyImg(psi(i,1)-half_kernel:psi(i,1)+half_kernel, ...
%                                       psi(i,2)-half_kernel:psi(i,2)+half_kernel));
    tmp_nhoods_r = noisyImg(psi(i,1)-half_kernel:psi(i,1)+half_kernel, ...
                            psi(i,2)-half_kernel:psi(i,2)+half_kernel, 1);
    tmp_nhoods_g = noisyImg(psi(i,1)-half_kernel:psi(i,1)+half_kernel, ...
                            psi(i,2)-half_kernel:psi(i,2)+half_kernel, 2);
    tmp_nhoods_b = noisyImg(psi(i,1)-half_kernel:psi(i,1)+half_kernel, ...
                            psi(i,2)-half_kernel:psi(i,2)+half_kernel, 3);
    neighborhoods(:,i) = [tmp_nhoods_r(:); tmp_nhoods_g(:); tmp_nhoods_b(:)];
end

% Perform PCA on Randomly Selected Neighborhoods
% M = kernel_edge^2;
[eig_vec,eig_val] = deNoise2D_PND_PCA(neighborhoods);

% % Show top 6 neighborhoods
% figure(1)
% for i = 1:6
%     subplot(2,3,i);
%     imshow(reshape(eig_vec(:,end-i+1),kernel_edge,kernel_edge));
%     title(i)
% end

% Capture Smallest Eigenvalue
%sigma_hat = sqrt(eig_val(1,1));

% -----------Parallel Analysis-------------
d = deNoise2D_PND_parallel(neighborhoods,eig_val);


% Use only the d largest eigenvectors as our space
b = eig_vec(:,end:-1:end-d+1);

% Estimate h
if (d <= 8)
    m = 2.84; c = 13.81/256;
elseif (d <= 15)
    m = 3.15; c = 22.55/256;
elseif (d < 35)
    m = 3.9; c = 29.31/256;
else
    m = 5.43; c = 29.17/256;
end
h = m*sigma+c;

% Project all neighborhoods into the d-dimensional subspace
all_nhoods = zeros(height,width,d);
parfor i = half_kernel+1:height-half_kernel
    %if(mod(i,50) == 0); fprintf('Projecting Row %d...\n',i); end
    for j = half_kernel+1:width-half_kernel
%         all_nhoods(i,j,:) = b'*vec(noisyImg(i-half_kernel:i+half_kernel, ...
%                                             j-half_kernel:j+half_kernel));
        tmp_noisyImg_r = noisyImg(i-half_kernel:i+half_kernel, ...
                                  j-half_kernel:j+half_kernel, 1);
        tmp_noisyImg_g = noisyImg(i-half_kernel:i+half_kernel, ...
                                  j-half_kernel:j+half_kernel, 2);
        tmp_noisyImg_b = noisyImg(i-half_kernel:i+half_kernel, ...
                                  j-half_kernel:j+half_kernel, 3);
        all_nhoods(i,j,:) = b'*[tmp_noisyImg_r(:); tmp_noisyImg_g(:); tmp_noisyImg_b(:)];
    end
end

% Do NLM
fprintf('Doing NLM\n')
deNoisedImg = noisyImg;
for i = half_window+half_kernel+1:height-half_window-half_kernel
    if(mod(i,10) == 0); fprintf('Denoising Row %d...\n',i);end
    parfor j = half_window+half_kernel+1:width-half_window-half_kernel
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
        % Normalize weights
        weights = weights .* exp( - eucDistsSq / hSqEuclidian );
        weights = 1/(sum(weights(:))).*weights;
        weights = repmat(weights, [1,1,3]);
        % Estimate Pixel
        u_tmp = noisyImg(i-half_window:i+half_window,j-half_window:j+half_window,:) ...
                .*weights;
        deNoisedImg(i,j,:) = sum(sum(u_tmp));
    end
end

% figure(2);imshow(img);title('Original')
% figure(3);imshow(noisyImg);title(sprintf('Noisy - sigma = %d', sigma*256))
% figure(4);imshow(deNoisedImg);title('Denoised')
% 
% MSE =  norm(vec(img(half_window+1:end-half_window, ...
%                     half_window+1:end-half_window))... 
%             - ...
%             vec(deNoisedImg(half_window+1:end-half_window, ...
%                             half_window+1:end-half_window)) ...
%             ,2);
% disp(sprintf('MSE = %d',MSE))

%-- show output image
% imshow( deNoisedImg, [] );
% drawnow; % make sure it's displayed
% pause(0.01); % make sure it's displayed


borderSize = half_kernel+half_window+1;
%-- copy output images
output = struct();
output.deNoisedImg = deNoisedImg;
output.prefix = 'PND_Euc_';
output.borderSize = borderSize;
