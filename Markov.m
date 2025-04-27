% MAIN SCRIPT TO GENERATE MUSIC USING MELODY + HARMONY SOM

%% Step 1: Load MIDI Data
folderPaths = { ...
    '/Users/hannahfindlay/Library/CloudStorage/OneDrive-UniversityofAberdeen/MATLAB/processmidifiles/Glass/', ...
    '/Users/hannahfindlay/Library/CloudStorage/OneDrive-UniversityofAberdeen/MATLAB/processmidifiles/Beatles/', ...
    '/Users/hannahfindlay/Library/CloudStorage/OneDrive-UniversityofAberdeen/MATLAB/processmidifiles/MilesDavis/', ...
    '/Users/hannahfindlay/Library/CloudStorage/OneDrive-UniversityofAberdeen/MATLAB/processmidifiles/Beethoven/', ...
    '/Users/hannahfindlay/Library/CloudStorage/OneDrive-UniversityofAberdeen/MATLAB/processmidifiles/Brahms/', ...
    '/Users/hannahfindlay/Library/CloudStorage/OneDrive-UniversityofAberdeen/MATLAB/processmidifiles/Mozart/', ...
    '/Users/hannahfindlay/Library/CloudStorage/OneDrive-UniversityofAberdeen/MATLAB/processmidifiles/StevieWonder/', ...
    '/Users/hannahfindlay/Library/CloudStorage/OneDrive-UniversityofAberdeen/MATLAB/processmidifiles/Tchaikovsky/' ...
};

allNmat = []; 
harmonyChords = [];

for f = 1:length(folderPaths)
    midiFiles = dir(fullfile(folderPaths{f}, '*.mid'));
    for i = 1:length(midiFiles)
        fullPath = fullfile(folderPaths{f}, midiFiles(i).name);
        if ~isfile(fullPath), continue; end
        try
            [nmat, chordData] = processmidifile(fullPath);
            if ~isempty(nmat), allNmat = [allNmat; nmat]; end
            if ~isempty(chordData), harmonyChords = [harmonyChords; chordData]; end
        catch, continue;
        end
    end
end

disp(['Final size of allNmat: ', num2str(size(allNmat, 1)), ' x ', num2str(size(allNmat, 2))]);
disp(['Final size of harmonyChords: ', num2str(size(harmonyChords, 1)), ' x ', num2str(size(harmonyChords, 2))]);

%% Step 2: Detect Melody and Harmony Objects
uploadedImages = {'MultiObject2 6.jpeg'};
allMelodyObjects = []; allHarmonyObjects = [];
for i = 1:length(uploadedImages)
    [melodyObjects, harmonyObjects] = detectObjectsWithSAM(uploadedImages{i});
    allMelodyObjects = [allMelodyObjects; melodyObjects]; 
    allHarmonyObjects = [allHarmonyObjects; harmonyObjects];
end

disp(['Total Melody Objects: ', num2str(length(allMelodyObjects))]);
disp(['Total Harmony Objects: ', num2str(length(allHarmonyObjects))]);

%% Step 3: Generate Melody with Markov Chain
transitionMatrix = calculateProbabilityMatrix(allNmat(:,4));
generatedMelodySequences = [];

if ~isempty(allMelodyObjects)
    objectAreas = [allMelodyObjects.Area];
    normAreas = (objectAreas - min(objectAreas)) / (max(objectAreas) - min(objectAreas) + eps);
    startNotes = round(normAreas * (108 - 21) + 21);
    startTime = 0;
    for objIdx = 1:length(allMelodyObjects)
        startNote = startNotes(objIdx);
        validNotes = unique(allNmat(:,4));
        if ~ismember(startNote, validNotes)
            [~, closestIdx] = min(abs(validNotes - startNote));
            startNote = validNotes(closestIdx);
        end
        numNotes = max(1, abs(allMelodyObjects(objIdx).EulerNumber));
        objectMelody = generateMelodyWithMarkov(transitionMatrix, numNotes, startNote, allMelodyObjects(objIdx));
        for n = 1:numNotes
            duration = mapBrightnessToDuration(allMelodyObjects(objIdx).Brightness);
            velocity = allMelodyObjects(objIdx).Velocity;
            generatedMelodySequences = [generatedMelodySequences; startTime, objectMelody(n), duration, velocity];
            startTime = startTime + duration;
        end
    end
    disp('Generated Melody Sequences:');
    disp(generatedMelodySequences);
end

%% Step 4: Train Harmony SOM
harmonyFeatures = [];
if ~isempty(allHarmonyObjects)
    harmonyFeatures = [[allHarmonyObjects.SpatialFrequency]', ...
                       [allHarmonyObjects.Brightness]', ...
                       [allHarmonyObjects.Contrast]', ...
                       rescale([allHarmonyObjects.Area]', 0, 1), ...
                       ones(length(allHarmonyObjects), 1) * 0.8];
end

midiFeatures = [];
if ~isempty(harmonyChords)
    midiFeatures = [[mod(harmonyChords(:, 1), 12) / 12], ...
                    mean(mod(harmonyChords(:, 1:3) - harmonyChords(:, 1), 12), 2) / 12, ...
                    range(harmonyChords(:, 1:3), 2) / 24, ...
                    min(harmonyChords(:, 4) / 2, 1), ...
                    harmonyChords(:, 5) / 127];
end

combinedHarmonyFeatures = [harmonyFeatures; midiFeatures];
if isempty(combinedHarmonyFeatures) || all(combinedHarmonyFeatures(:) == 0)
    error('No valid harmony data available for SOM training!');
end

harmonySOM = trainHarmonySOM(combinedHarmonyFeatures);
disp('Step 4: SOM training complete.');

%% Step 5: Generate Harmony
% Define the SOM dimensions based on what is used during training
 if isa(harmonySOM, 'network') && isprop(harmonySOM, 'IW') && ...
   ~isempty(harmonySOM.IW) && all(cellfun(@(c) ~isempty(c), harmonySOM.IW))
    generatedHarmonySequence = generateHarmonyWithSOM( harmonySOM, allHarmonyObjects, allMelodyObjects);
else
    warning('Harmony SOM is invalid or empty! Using fallback harmony generation.');
    generatedHarmonySequence = [];
end

if ~isempty(generatedHarmonySequence)
    disp('Generated Harmony Sequence:');
    disp(generatedHarmonySequence);
end

%% Step 6: Save MIDI File and YOLO detection
outputFilename = 'generated_music.mid';
HarmonyTempo = max(80, min(240, length(allHarmonyObjects) * 30));
MelodyTempo = max(80, min(240, length(allMelodyObjects) * 40));

if ~isempty(generatedMelodySequences) && ~isempty(generatedHarmonySequence)
    combineMelodyHarmony(generatedMelodySequences, generatedHarmonySequence, outputFilename, MelodyTempo, HarmonyTempo);
    disp(['Generated MIDI file saved as: ', outputFilename]);
elseif ~isempty(generatedMelodySequences)
    disp('Only melody sequence available for MIDI output.');
    combineMelodyHarmony(generatedMelodySequences, [], outputFilename, MelodyTempo);
elseif ~isempty(generatedHarmonySequence)
    disp('Only harmony sequence available for MIDI output.');
    combineMelodyHarmony([], generatedHarmonySequence, outputFilename, HarmonyTempo);
else
    warning('No melody or harmony sequences were generated. Cannot create MIDI file.');
end

