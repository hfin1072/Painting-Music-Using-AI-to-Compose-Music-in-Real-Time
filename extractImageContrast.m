function contrast = extractImageContrast(img)
    % Ensure input is grayscale
    if size(img, 3) == 3
        img = rgb2gray(img); % Convert to grayscale
    end
    
    % Convert image to double precision for calculations
    img = double(img);
    
    % Calculate maximum and minimum intensity values
    maxIntensity = max(img(:));
    minIntensity = min(img(:));
    
    % Avoid division by zero (in case maxIntensity + minIntensity == 0)
    if (maxIntensity + minIntensity) == 0
        contrast = 0; % No contrast if the image is uniform
    else
        % Calculate contrast using the standard formula
        contrast = (maxIntensity - minIntensity) / (maxIntensity + minIntensity);
    end
    
    % Ensure contrast is in the range [0, 1]
    contrast = max(0, min(contrast, 1));
end