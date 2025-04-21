function [melodyObjects, harmonyObjects] = detectObjectsWithSAM(imagePath)
    % Read the input image.
    img = imread(imagePath);
    fprintf('\nSegmenting using Segment Anything Model.\n');
    disp('---------------------------------------------');

    % Run SAM segmentation.
    [masks, scores] = imsegsam(img, MinObjectArea=2000, ScoreThreshold=0.25);

    if masks.NumObjects == 0
        warning('No objects detected by SAM.');
        melodyObjects = []; harmonyObjects = []; return;
    end

    % Convert the logical mask object to a label matrix.
    labelMatrix = labelmatrix(masks);
    
    % Get region properties.
    stats = regionprops(masks, 'Centroid', 'Area', 'BoundingBox', 'PixelIdxList');
    fprintf('[Total objects found by regionprops: %d\n', numel(stats));

    % Sort regions by centroid (row and column).
    [~, sortIdx] = sortrows(cat(1, stats.Centroid), [1 2]);
    stats = stats(sortIdx);
    stats = stats(arrayfun(@(s) all(~isnan(s.Centroid)) && all(s.Centroid > 0), stats));
    fprintf('[Objects after NaN filtering: %d\n', numel(stats));

    % Group overlapping masks into logical objects
    overlapThreshold = 0.05;
    assigned = false(1, numel(stats));
    groups = {};

    for i = 1:numel(stats)
        if assigned(i), continue; end
        group = i;
        assigned(i) = true;
        bb1 = stats(i).BoundingBox;
        for j = i+1:numel(stats)
            if assigned(j), continue; end
            bb2 = stats(j).BoundingBox;
            interArea = rectint(bb1, bb2);
            minArea = min(bb1(3)*bb1(4), bb2(3)*bb2(4));
            if interArea / minArea > overlapThreshold
                group(end+1) = j;
                assigned(j) = true;
            end
        end
        groups{end+1} = group;
    end

    fprintf('[Grouped into %d merged logical objects\n', numel(groups));

    % Define an empty template for object data ---
    emptyTemplate = struct(...
        'Brightness', [], 'Contrast', [], 'NoteSpacing', [], ...
        'SpatialFrequency', [], 'Area', [], 'Perimeter', [], ...
        'Velocity', [], 'EulerNumber', [], 'Centroid', [], ...
        'BoundingBox', [], 'IsFirstMelody', false, ...
        'ClusterID', [], 'ObjectID', [], 'ParentMelodyIDs', []);
    melodyObjects = emptyTemplate([]);
    harmonyObjects = emptyTemplate([]);
    allObjects = emptyTemplate([]);

    clusterCounter = 1;
    imgDiag = sqrt(size(img,1)^2 + size(img,2)^2);
    maxDistanceThreshold = 0.35 * imgDiag;
    fprintf('maxDistanceThreshold set to %.2f (35%% of image diagonal)\n', maxDistanceThreshold);

    % Display the original image with segmentation boundaries
    figure; 
    imshow(img); 
    hold on; 
    title('Clustered Objects');
    colors = jet(numel(groups));

    objId = 1;
    for g = 1:numel(groups)
        groupIdx = groups{g};
        combinedMask = false(size(labelMatrix));
        groupArea = 0;
        combinedPixels = [];
        centroids = [];
        for k = groupIdx
            combinedMask(stats(k).PixelIdxList) = true;
            groupArea = groupArea + stats(k).Area;
            combinedPixels = [combinedPixels; stats(k).PixelIdxList];
            centroids = [centroids; stats(k).Centroid];
        end

        currCentroid = mean(centroids, 1);
        [y, x] = find(combinedMask);
        if ~isempty(x)
            currCentroid = [mean(x), mean(y)];
        end

        % Mark and label each object.
        plot(currCentroid(1), currCentroid(2), 'ro', 'MarkerSize', 8);
        text(currCentroid(1)+10, currCentroid(2), sprintf('%d', objId), 'Color', 'r', 'FontSize', 12);
        text(currCentroid(1), currCentroid(2)-15, sprintf('%d parts', numel(groupIdx)), 'Color', 'g', 'FontSize', 10);
        boundary = bwboundaries(combinedMask);
        for b = 1:length(boundary)
            plot(boundary{b}(:,2), boundary{b}(:,1), 'Color', colors(g,:), 'LineWidth', 1.5);
        end

        obj = stats(groupIdx(1));
        obj.Area = groupArea;
        obj.Centroid = currCentroid;
        obj.PixelIdxList = combinedPixels;

        objectData = extractObjectData(img, labelMatrix, obj);
        objectData.ObjectID = objId;
        objectData.Centroid = currCentroid;

        if isempty(allObjects)
            objectData.IsFirstMelody = true;
            objectData.ClusterID = clusterCounter;
            objectData.ParentMelodyIDs = [];
            melodyObjects = [melodyObjects; objectData];
            fprintf('[DEBUG] Object #%d is first melody (Cluster %d)\n', objId, clusterCounter);
            clusterCounter = clusterCounter + 1;
        else
            prevCentroid = allObjects(end).Centroid;
            dist = norm(currCentroid - prevCentroid);
            if dist < maxDistanceThreshold
                objectData.IsFirstMelody = false;
                objectData.ClusterID = allObjects(end).ClusterID;
                objectData.ParentMelodyIDs = allObjects(end).ObjectID;
                harmonyObjects = [harmonyObjects; objectData];
                fprintf('[DEBUG] Object #%d added as harmony → Cluster %d, Parent #%d\n', objId, objectData.ClusterID, objectData.ParentMelodyIDs);
            else
                objectData.IsFirstMelody = true;
                objectData.ClusterID = clusterCounter;
                objectData.ParentMelodyIDs = [];
                melodyObjects = [melodyObjects; objectData];
                fprintf('[DEBUG] Object #%d starts new melody → Cluster %d\n', objId, clusterCounter);
                clusterCounter = clusterCounter + 1;
            end
        end
        allObjects = [allObjects; objectData];
        objId = objId + 1;
    end

    % Save the segmented mask overlay image
    coloredOverlay = labeloverlay(img, labelMatrix, 'Colormap', jet(max(labelMatrix(:))), 'Transparency', 0.2);
    figure; 
    imshow(coloredOverlay); 
    title('Colored Overlay of Segmented Masks');
    print('Segmented_Masks','-dpng');

    disp(' ');
    disp('Final Cluster Summary');
    allClusters = unique([melodyObjects.ClusterID]);
    for c = allClusters
        mel = sum([melodyObjects.ClusterID] == c);
        har = 0;
        if ~isempty(harmonyObjects)
            har = sum([harmonyObjects.ClusterID] == c);
        end
        fprintf('Cluster %d: %d Melody, %d Harmony\n', c, mel, har);
    end

    hold off;
      
end

function objectData = extractObjectData(img, labelMatrix, obj)
    persistent allPerimeters;
    if isempty(allPerimeters)
        allPerimeters = [];
    end

    bbox = obj.BoundingBox;
    objectImage = imcrop(img, bbox);
    objMask = false(size(labelMatrix));
    objMask(obj.PixelIdxList) = true;

    props = regionprops(objMask, 'Perimeter', 'EulerNumber');
    perimeter = props.Perimeter;
    eulerNumber = props.EulerNumber;

    allPerimeters(end+1) = perimeter;
    scaled = (perimeter - min(allPerimeters)) / (max(allPerimeters) - min(allPerimeters) + eps);
    velocity = round(40 + scaled * (127 - 40));
    velocity = min(max(velocity, 30), 127);
    eulerNumber = round(rescale(eulerNumber, 3, 12, 'InputMin', -100, 'InputMax', 100));
    eulerNumber = max(3, min(12, eulerNumber));

    objectData = struct(...
        'Brightness', extractImageBrightness(objectImage), ...
        'Contrast', extractImageContrast(objectImage), ...
        'NoteSpacing', calculateNoteSpacing(objectImage), ...
        'SpatialFrequency', spatial_frequency(objectImage), ...
        'Area', obj.Area, ...
        'Perimeter', perimeter, ...
        'Velocity', velocity, ...
        'EulerNumber', eulerNumber, ...
        'Centroid', obj.Centroid, ...
        'BoundingBox', obj.BoundingBox, ...
        'IsFirstMelody', false, ...
        'ClusterID', [], ...
        'ObjectID', [], ...
        'ParentMelodyIDs', []);
end
