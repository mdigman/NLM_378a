function output = deNoise2D_PND_Bayes( noisyImg, config )

[height,width] = size(noisyImg);
kernel_edge = 7;
window_edge = 21;
half_kernel = floor(kernel_edge/2);
half_window = floor(window_edge/2);
sigma = config.noiseSig;

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
    tmp_nhoods = noisyImg(psi(i,1)-half_kernel:psi(i,1)+half_kernel, ...
                          psi(i,2)-half_kernel:psi(i,2)+half_kernel);
    neighborhoods(:,i) = tmp_nhoods(:);
end

% Perform PCA on Randomly Selected Neighborhoods
M = kernel_edge^2;
[eig_vec,eig_val] = deNoise2D_PND_PCA(neighborhoods);

% Capture Smallest Eigenvalue
% sigma_hat = sqrt(eig_val(1,1));

% -----------Parallel Analysis-------------
d = deNoise2D_PND_parallel(neighborhoods,eig_val)


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
h = m*sigma+c;      % Using sigma instead of PND-generated sigma_hat

% Project all neighborhoods into the d-dimensional subspace
all_nhoods = zeros(height,width,d);
for i = half_kernel+1:height-half_kernel
    if(mod(i,50) == 0); fprintf('Projecting Row %d...\n',i); end
    for j = half_kernel+1:width-half_kernel
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
        % Get center neighborhood
        center = reshape(all_nhoods(i,j,:),d,1);
        % Get weights using Bayesian weighting
        weights = zeros(window_edge,window_edge);
        for k = -half_window:half_window
            for l = -half_window:half_window
                f_d = reshape(all_nhoods(i+k,j+l,:),d,1);
                dist0 = norm(center-f_d,2)^2/(2*sigma^2);
                weights(k+half_window+1,l+half_window+1) = ...
                                            exp(-(dist0/2 + (1-d/2)*log(dist0)));
            end
        end
        % Normalize weights
        weights = 1/(sum(weights(:))).*weights;
        % Estimate Pixel
        u_tmp = noisyImg(i-half_window:i+half_window,j-half_window:j+half_window) ...
                .*weights;
        deNoisedImg(i,j) = sum(u_tmp(:));
    end
end

borderSize = half_kernel+half_window+1;
%-- copy output images
output = struct();
output.deNoisedImg = deNoisedImg;
output.prefix = 'PND_Bayes_';
output.borderSize = borderSize;