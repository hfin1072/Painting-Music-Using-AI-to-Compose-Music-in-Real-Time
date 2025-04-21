function generatedHarmony = generateHarmonyWithSOM(harmonySOM, harmonyObjects, melodyObjects)
    if nargin < 3
        error('Missing required inputs: harmonySOM, harmonyObjects, melodyObjects.');
    end

    totalChords = 0;
    for i = 1:length(harmonyObjects)
        totalChords = totalChords + max(1, abs(harmonyObjects(i).EulerNumber));
    end

    generatedHarmony = zeros(totalChords, 10);
    currentTime = 0;
    chordIndex = 1;
    previousChords = [];  % Each row stores one chord (padded to a fixed length)
    neuronMapping = zeros(length(harmonyObjects), 1);
    usedNeurons = [];
    clusterIDs = [harmonyObjects.ClusterID];
    totalHarmonyGroups = length(unique(clusterIDs));

    somTrained = isprop(harmonySOM, 'IW') && ~any(cellfun(@isempty, harmonySOM.IW));
    if ~somTrained
        warning('Harmony SOM appears to be untrained! Using fallback mapping.');
    end

    for i = 1:length(harmonyObjects)
        obj = harmonyObjects(i);
        spatialFreq = obj.SpatialFrequency;
        brightness = obj.Brightness;
        contrast = obj.Contrast;
        area = obj.Area;

        parentContrast = 0.5;
        parentDuration = 0.5;
        numParents = 0;
        parentInfluence = 0;

        if isfield(obj, 'ParentID') && ~isempty(obj.ParentID)
            obj.ParentMelodyIDs = obj.ParentID;
        end

        if isfield(obj, 'ParentMelodyIDs') && ~isempty(obj.ParentMelodyIDs)
            obj.ParentMelodyIDs = unique(obj.ParentMelodyIDs(:)');
            numParents = length(obj.ParentMelodyIDs);
            parentID = obj.ParentMelodyIDs(1);
            if parentID > 0 && parentID <= length(melodyObjects)
                if isfield(melodyObjects(parentID), 'Contrast')
                    parentContrast = melodyObjects(parentID).Contrast;
                end
                if isfield(melodyObjects(parentID), 'Duration')
                    parentDuration = melodyObjects(parentID).Duration;
                end
            end
            parentSum = 0;
            for p = 1:numParents
                currID = obj.ParentMelodyIDs(p);
                if currID > 0 && currID <= length(melodyObjects)
                    parentSum = parentSum + currID;
                end
            end
            parentInfluence = mod(parentSum / numParents, 12) / 12;
        end

        inputFeatures = [rescale(spatialFreq, 0, 1); 
                         rescale(brightness, 0, 1); 
                         rescale(contrast, 0, 1); 
                         rescale(area, 0, 1); 
                         0.8 + parentInfluence] + ((rand(5,1)-0.5)*0.1);

        if somTrained
            try
                activation = sim(harmonySOM, inputFeatures);
                originalNeuron = vec2ind(activation);
                [~, sortedNeurons] = sort(activation, 'descend');
                neuronIdx = [];
                for k = 1:length(sortedNeurons)
                    candidate = sortedNeurons(k);
                    if ~ismember(candidate, usedNeurons)
                        neuronIdx = candidate;
                        break;
                    end
                end
                if isempty(neuronIdx)
                    neuronIdx = randi([21,108]);
                end
                usedNeurons(end+1) = neuronIdx;
                neuronMapping(i) = neuronIdx;
                rootNote = round(rescale(neuronIdx,21,108));
                fprintf("Harmony object %d original neuron #%d - assigned neuron #%d\n", i, originalNeuron, neuronIdx);
            catch
                rootNote = randi([21,108]);
            end
        else
            rootNote = randi([21,108]);
        end

        chordsPerObject = max(1, abs(obj.EulerNumber));
        if totalHarmonyGroups > 1 && i > 1
            baseMajor = [0,4,7];
            baseMinor = [0,3,7];
            extension = [11,14,17,21];
            extraNotes = min(i-1, length(extension));
            if parentContrast > 0.5
                chordType = [baseMajor, extension(1:extraNotes)];
            else
                chordType = [baseMinor, extension(1:extraNotes)];
            end
        else
            if parentContrast > 0.5
                chordType = [0,4,7];
            else
                chordType = [0,3,7];
            end
        end

        for j = 1:chordsPerObject
            % Compute the base chord.
            baseChord = rootNote + chordType;
            while any(baseChord>108)
                overflowIndices = find(baseChord>108);
                baseChord(overflowIndices) = baseChord(overflowIndices)-12;
            end

            % Voicing Pool Method
            numCandidates = length(baseChord);
            voicingPool = cell(1, numCandidates);
            for inv = 0:(numCandidates-1)
                candidateVoicing = circshift(baseChord, -inv);
                if inv > 0
                    candidateVoicing(end) = candidateVoicing(end)+12;
                end
                while any(candidateVoicing>108)
                    candidateVoicing(candidateVoicing>108) = candidateVoicing(candidateVoicing>108)-12;
                end
                while any(candidateVoicing<21)
                    candidateVoicing(candidateVoicing<21) = candidateVoicing(candidateVoicing<21)+12;
                end
                voicingPool{inv+1} = candidateVoicing;
            end

            poolIndex = mod(j-1, numCandidates)+1;
            selectedCandidate = voicingPool{poolIndex};

            if chordRepeated(selectedCandidate, previousChords)
                uniqueFound = false;
                for k = 1:numCandidates
                    poolIndex = mod(poolIndex + k - 1, numCandidates)+1;
                    candidateTemp = voicingPool{poolIndex};
                    if ~chordRepeated(candidateTemp, previousChords)
                        selectedCandidate = candidateTemp;
                        uniqueFound = true;
                        break;
                    end
                end
                if ~uniqueFound
                    variation = randi([-1,1], size(selectedCandidate));
                    candidateTemp = selectedCandidate + variation;
                    candidateTemp(candidateTemp>108) = candidateTemp(candidateTemp>108)-12;
                    candidateTemp(candidateTemp<21) = candidateTemp(candidateTemp<21)+12;
                    selectedCandidate = candidateTemp;
                end
            end

            newChord = selectedCandidate;
            maxNotes = min(2+i, length(newChord));
            extendedChord = newChord(1:maxNotes);
            fprintf("Harmony #%d → Parents: %s - FinalChord: %s\n", i, mat2str(obj.ParentMelodyIDs), mat2str(extendedChord));

            tempChord = zeros(1,7);
            tempChord(1:length(extendedChord)) = extendedChord;
            previousChords = [previousChords; tempChord];

            generatedHarmony(chordIndex, 1:length(extendedChord)) = extendedChord;
            generatedHarmony(chordIndex, 8) = parentDuration;
            if isfield(obj, 'Velocity') && ~isempty(obj.Velocity)
                velocity = obj.Velocity;
            else
                perimeter = max(1,obj.Perimeter);
                velocity = round(40 + 87*tanh(perimeter/10000));
            end
            generatedHarmony(chordIndex, 9) = velocity;
            if chordIndex>1
                prevDuration = generatedHarmony(chordIndex-1, 8);
                currentTime = currentTime+prevDuration;
            end
            generatedHarmony(chordIndex, 10) = currentTime;
            chordIndex = chordIndex+1;
        end
    end

    assignin('base','generatedHarmonySequence',generatedHarmony);
    disp('Generated Harmony Sequence:');
    disp(generatedHarmony);

    if ~isempty(neuronMapping)
        % Original Scatter Plot (Neuron Mapping) 
        figure;
        scatter(1:length(neuronMapping), neuronMapping, 50, clusterIDs, 'filled');
        colormap(jet(length(unique(clusterIDs))));
        colorbar;
        xlabel('Harmony Object Index');
        ylabel('SOM Neuron Index');
        title('SOM Neuron Mapping per Harmony Object (Color by Cluster)');
        grid on;
        print('SOM_Cluster_Data','-dpng');

        % Detailed SOM Topology with Harmony Mapping 
        % Display a full SOM topology using plotsomtop.
        figure;
        plotsomtop(harmonySOM);   % Display the SOM topology grid
        title('SOM Topology with Harmony Object Mappings');
        hold on;
        % Extract the positions of neurons.
        positions = harmonySOM.layers{1}.positions;  % Each column is [x; y]
        w = harmonySOM.IW{1};  % SOM weight matrix

        % For each harmony object, plot its winning neuron and highlight neighbors.
        for i = 1:length(neuronMapping)
            winIdx = neuronMapping(i);
            posWin = positions(:, winIdx);
            % Mark winning neuron with a large black circle.
            plot(posWin(1), posWin(2), 'ko', 'MarkerSize', 12, 'LineWidth', 2);
            % Label the neuron with the harmony object number.
            text(posWin(1)+0.5, posWin(2), num2str(i), 'Color', 'k', 'FontSize', 10);

            % Calculate Euclidean distances between this neuron's weight vector and all others.
            winWeight = w(winIdx, :);
            dists = sqrt(sum((w - repmat(winWeight, size(w,1), 1)).^2, 2));
            % Use a threshold to find close neurons (adjust threshold as needed).
            threshold = 0.5;
            neighborIdx = find(dists < threshold);
            for n = 1:length(neighborIdx)
                if neighborIdx(n) == winIdx
                    continue;
                end
                posNeighbor = positions(:, neighborIdx(n));
                plot(posNeighbor(1), posNeighbor(2), 'rs', 'MarkerSize', 8, 'LineWidth', 1);
            end
        end
        hold off;
        print('SOM_Topology_HarmonyMapping','-dpng');
    end
end

% Check if candidateChord (sorted) equals any previous chord.
function repeated = chordRepeated(candidateChord, previousChords)
    repeated = false;
    if isempty(previousChords)
        return;
    end
    len = length(candidateChord);
    for idx = 1:size(previousChords,1)
        prevChord = previousChords(idx,:);
        % Remove zero padding.
        prevChord = prevChord(prevChord > 0);
        cmpLen = min(len, length(prevChord));
        if cmpLen > 0 && isequal(sort(candidateChord(1:cmpLen)), sort(prevChord(1:cmpLen)))
            repeated = true;
            return;
        end
    end
end
