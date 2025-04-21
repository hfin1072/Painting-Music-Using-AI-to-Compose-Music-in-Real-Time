function brightness = extractImageBrightness(img)
    % Ensure input is grayscale
    if size(img, 3) == 3
        img = rgb2gray(img); % Convert to grayscale
    end
    brightness = mean(img(:)) / 255; % Normalize brightness (0 to 1)
end
