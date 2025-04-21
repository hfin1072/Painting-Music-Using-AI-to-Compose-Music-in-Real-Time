function detector = trainDrumYOLOFromQuickDraw(imageFolder, outputDetectorFile)
% Trains a YOLOv3 object detector on QuickDraw drum images using yolov3ObjectDetector API.

% Load labeled training data
if ~isfile('trainingData.mat')
    error('trainingData.mat not found. Run convertQuickDrawToTrainingData first.');
end
load('trainingData.mat', 'trainingData');

% Limit to 1% of the dataset for faster training
subsetSize = round(0.01 * height(trainingData));
trainingData = trainingData(1:subsetSize, :);

% Confirm dataset
disp(['Loaded ', num2str(height(trainingData)), ' labeled images for training (1% subset).']);

% Preprocess the data for training and convert grayscale to RGB
imds = imageDatastore(trainingData.imageFilename, ...
    'ReadFcn', @(filename) repmat(imread(filename), 1, 1, 3));

blds = boxLabelDatastore(trainingData(:,2));
trainingDS = combine(imds, blds);

% Estimate anchor boxes for YOLOv3 (3 groups of 3 boxes each)
numAnchors = 9;
estimatedAnchors = estimateAnchorBoxes(trainingDS, numAnchors);
anchorBoxes = {
    estimatedAnchors(1:3, :);
    estimatedAnchors(4:6, :);
    estimatedAnchors(7:9, :)
};

% Define YOLOv3 detector using pretrained backbone
inputSize = [224 224 3];
detector = yolov3ObjectDetector("darknet53-coco", trainingDS, anchorBoxes, ...
    InputSize=inputSize, ClassNames="drum");

% Set training options
options = trainingOptions('sgdm', ...
    'InitialLearnRate', 1e-3, ...
    'MaxEpochs', 20, ...
    'MiniBatchSize', 16, ...
    'Shuffle', 'every-epoch', ...
    'Verbose', true, ...
    'VerboseFrequency', 10, ...
    'Plots', 'training-progress');

% Train the detector
[detector, info] = trainYOLOv3ObjectDetector(trainingDS, detector, options);

% Save the trained detector
save(outputDetectorFile, 'detector');

disp(['YOLOv3 drum detector trained and saved to ', outputDetectorFile]);
end
