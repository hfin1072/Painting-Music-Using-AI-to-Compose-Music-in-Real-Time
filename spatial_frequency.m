function normalized_spatial_freq = spatial_frequency(img)
    % Computes the 2D FFT and normalizes the spatial frequency to range [0, 1]

    % Ensure the input is a valid image matrix
    if ~isnumeric(img)
        error('Input must be an image matrix, not a file path.');
    end
    
    % Convert to grayscale if it's a color image
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    
    % Convert to double precision for FFT processing
    img = double(img);
    
    % Compute the 2D FFT
    fft_image = fft2(img);
    
    % Shift the zero-frequency component to the center
    fft_image_shifted = fftshift(fft_image);
    
    % Calculate the magnitude spectrum
    magnitude_spectrum = abs(fft_image_shifted);
    
    % Get the min and max values of the spatial frequency spectrum
    min_freq = min(magnitude_spectrum(:));  % Minimum frequency (low-frequency component)
    max_freq = max(magnitude_spectrum(:));  % Maximum frequency (high-frequency component)
    
    % Compute the mean spatial frequency
    spatial_freq = mean(magnitude_spectrum(:));
    
    % Normalize the spatial frequency between 0 and 1
    normalized_spatial_freq = (spatial_freq - min_freq) / (max_freq - min_freq + eps); % Avoid division by zero
    
    %disp(['Normalized Spatial Frequency: ', num2str(normalized_spatial_freq)]);
end
