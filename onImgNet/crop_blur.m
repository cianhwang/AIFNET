    clc;clear;close all
addpath('~/Downloads/ILSVRC2012_img_val/')
prefix = "ILSVRC2012_val_";
surfix = ".JPEG";
crop_size = 72;
k = 19869;
for i = 19878:21000
    disp(i)
    filename = strcat(prefix, num2str(i, '%08d'), surfix);
    I = im2double(imread(filename));
    [m, n, ~] = size(I);

    [x_idx, y_idx] = findSaliency(I, crop_size);

    try
    I_crop = I(x_idx:x_idx+crop_size-1,y_idx:y_idx+crop_size-1,:);
    catch
        continue;
    end
    %figure, imshow(I_crop);

    mask = ones(crop_size, crop_size);
    bw = activecontour(I_crop, mask, 100);
    %figure, imshow(bw);
    se = strel('disk',10);
    openBW = double(imopen(bw,se));
    %figure, imshow(openBW);
    openBW3 = double(repmat(uint8(openBW), [1, 1, 3]));
    
    GaussianBlurParam1 = (2*rand+3);
    GaussianBlurParam2 = (2*rand+3);
    
	ff_merged = merge_image(I_crop.*openBW3, openBW, GaussianBlurParam1, I_crop);
    nf_merged = merge_image(I_crop.*openBW3, openBW, 0.1, imgaussfilt(I_crop,GaussianBlurParam2));
    
%     img1 = imgaussfilt(I_crop.*openBW, GaussianBlurParam1) + I_crop.*(1-openBW);
%  %   figure, imshow(img1);
%  	img2 = imgaussfilt(I_crop.*(1-openBW), GaussianBlurParam2) + I_crop.*openBW;
%   %  figure, imshow(img2);
    %figure, imshowpair(ff_merged,nf_merged, 'montage');
	imwrite(I_crop, strcat('~/Downloads/testcase_mass/',num2str(k, '%05d'), '_0.jpeg'));
    imwrite(ff_merged, strcat('~/Downloads/testcase_mass/', num2str(k, '%05d'), '_1.jpeg'));
    imwrite(nf_merged, strcat('~/Downloads/testcase_mass/', num2str(k, '%05d'), '_2.jpeg'));
    k = k+1;
end

function merged = merge_image(foreground, alpha, blur_sigma, background)
% expand 1 channel foreground alpha to 3 channel
alpha = padarray(alpha,[0,0,2],'post','replicate');
% blur foreground_image*alpha
foreground_to_add = imgaussfilt(alpha.*foreground, blur_sigma);
% apply complementary blurred alpha on background
blurred_alpha = imgaussfilt(alpha, blur_sigma);
background_to_add = (1-blurred_alpha).*background;
% multiply and sum
merged = foreground_to_add + background_to_add;
end

function [x_idx, y_idx] = findSaliency(I, crop_size)
    [m, n, ~] = size(I);
    x_bound = [max(0, floor(m/2)-100), min(m, floor(m/2)+99)];
    y_bound = [max(0, floor(n/2)-100), min(n, floor(n/2)+99)];
    tempx = randi(x_bound, 1000, 1);
    tempy = randi(y_bound, 1000, 1);
    max_diff = 0;
    x_idx = 1;
    y_idx = 1;
    for i = 1:1000
        try
       I_temp = I(tempx(i):tempx(i)+crop_size-1, tempy(i):tempy(i)+crop_size-1, :);
       diff_total = mean(diff(I_temp, 1, 1).^2, 'all') + mean(diff(I_temp, 1, 2).^2, 'all');
       if diff_total > max_diff
           x_idx = tempx(i);
           y_idx = tempy(i);
       end
        catch
            %disp(i);
            continue;
        end
    end
end

