function generatedMelody = generateMelodyWithMarkov(transitionMatrix, numNotes, startNote, melodyObject)
    if nargin < 4 || isempty(melodyObject)
        error('melodyObject input is missing or empty.');
    end
    
    generatedMelody = zeros(numNotes, 4); % [note, start_time, duration, velocity]
    generatedMelody(1, 1) = startNote;
    
    % Initialize timing based on note spacing
    currentTime = 0;
    generatedMelody(1, 2) = currentTime;
    
    maxRepeats = 3;  
    repeatCount = 0;  
    
    % Get note spacing from the melody object
    noteSpacing = melodyObject.NoteSpacing;
    
    for i = 1:numNotes
        % Choose the next note based on transition probabilities
        if i > 1
            probabilities = transitionMatrix(generatedMelody(i-1, 1), :);
            
            if sum(probabilities) == 0
                nextNote = randi([21, 108]);
            else
                nextNote = randsample(1:length(probabilities), 1, true, probabilities);
            end
            
            % Prevent excessive consecutive repetitions
            if nextNote == generatedMelody(i-1, 1)
                repeatCount = repeatCount + 1;
            else
                repeatCount = 0;
            end
            
            if repeatCount >= maxRepeats
                alternativeNotes = find(probabilities > 0 & (1:128) ~= generatedMelody(i-1, 1));
                if ~isempty(alternativeNotes)
                    nextNote = alternativeNotes(randi(length(alternativeNotes)));  
                end
                repeatCount = 0;
            end
            
            % Convert contrast into "Major" or "Minor"
            if melodyObject.Contrast >= 0.5
                scaleType = "Major";
            else
                scaleType = "Minor";
            end

            % Apply Scale Filtering 
            [nextNote, octave] = filterNoteToScale(nextNote, scaleType);
            
            % Scale pitch based on spatial frequency
            pitchFactor = round(rescale(melodyObject.SpatialFrequency, -6, 6));
            nextNote = nextNote + pitchFactor;
            
            generatedMelody(i, 1) = nextNote;
        end
        
        % Modify note duration based on brightness
        generatedMelody(i, 3) = mapBrightnessToDuration(melodyObject.Brightness);

        % Assign velocity based on object perimeter mapping
        generatedMelody(i, 4) = melodyObject.Velocity; % Use detected velocity
        
        % Set start time for this note (if not the first note)
        if i > 1
            % Note spacing calculation (ratio of edge pixels to total pixels)
            timeFactor = 1.0 + (0.5 * noteSpacing);  % Linear scaling
            currentTime = currentTime + (generatedMelody(i-1, 3) * timeFactor);
            generatedMelody(i, 2) = currentTime;
        end
    end
end
