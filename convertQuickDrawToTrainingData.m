function convertQuickDrawToTrainingData()
% Converts QuickDraw 'drums.ndjson' file to PNG images and saves bounding boxes.

inputFile = 'drums.ndjson';              % Path to downloaded QuickDraw file
outputImageFolder = 'QuickDrawImages';   % Where to save output PNGs
outputTableFile = 'trainingData.mat';    % Final table of image+labels

if ~exist(outputImageFolder, 'dir')
    mkdir(outputImageFolder);
end

fid = fopen(inputFile);
index = 1;
imageFilenames = {};
boxLabels = {};

while ~feof(fid)
    line = fgetl(fid);
    if isempty(line), continue; end

    try
        data = jsondecode(line);
        strokes = data.drawing;

        % Create blank white canvas
        img = ones(256, 256, 'uint8') * 255;

        % Draw strokes
        for s = 1:length(strokes)
            x = strokes{s}(1,:) * 2;  % scale to 256
            y = strokes{s}(2,:) * 2;
            for p = 1:length(x)-1
                img = insertShape(img, 'Line', [x(p), y(p), x(p+1), y(p+1)], ...
                    'Color', 'black', 'LineWidth', 3);
            end
        end

        % Convert to grayscale & binary
        img = rgb2gray(img);
        bw = imbinarize(img);
        stats = regionprops(bw, 'BoundingBox');

        if isempty(stats), continue; end
        bbox = stats(1).BoundingBox;  % [x y w h]

        % Save image
        filename = sprintf('drum_%04d.png', index);
        imwrite(img, fullfile(outputImageFolder, filename));

        % Save data
        imageFilenames{end+1,1} = fullfile(outputImageFolder, filename);
        boxLabels{end+1,1} = bbox;

        index = index + 1;

    catch
        % Skip malformed entries
        continue;
    end
end

fclose(fid);

% Save label table for YOLO training
trainingData = table(imageFilenames, boxLabels, 'VariableNames', {'imageFilename', 'drum'});
save(outputTableFile, 'trainingData');

disp(['Saved ', num2str(index-1), ' drum sketches as training images.']);
end