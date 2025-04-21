function combineMelodyHarmony(melodySequence, harmonySequence, outputFilename, melodyTempo, harmonyTempo)
%   melodySequence - Matrix format with [startTime, note, duration, velocity]
%   harmonySequence - Matrix format with [note1, note2, note3, ..., duration, velocity, startTime]
%   outputFilename - Output MIDI filename (string)
%   melodyTempo - Tempo for melody in BPM (default 120)
%   harmonyTempo - Tempo for harmony in BPM (default 120)

    if nargin < 4
        melodyTempo = 120;
    end
    if nargin < 5
        harmonyTempo = melodyTempo;
    end
    finalTempo = round((melodyTempo + harmonyTempo) / 2);
    nmat = [];
    melodyTotalDuration = 0;
    harmonyTotalDuration = 0;

    if ~isempty(melodySequence)
        for i = 1:size(melodySequence, 1)
            endTime = melodySequence(i, 1) + melodySequence(i, 3);
            if endTime > melodyTotalDuration
                melodyTotalDuration = endTime;
            end
        end
    end

    if ~isempty(harmonySequence)
        for i = 1:size(harmonySequence, 1)
            harmonyTotalDuration = harmonyTotalDuration + harmonySequence(i, 4);
        end
    end

    maxDuration = max(melodyTotalDuration, harmonyTotalDuration);

    if ~isempty(melodySequence)
        melodyNmat = [];
        currentTime = 0;
        while currentTime < maxDuration
            for i = 1:size(melodySequence, 1)
                startTimeSec = melodySequence(i, 1) + currentTime;
                pitch = melodySequence(i, 2);
                durationSec = melodySequence(i, 3);
                velocity = melodySequence(i, 4);

                if startTimeSec >= maxDuration
                    continue;
                end

                if startTimeSec + durationSec > maxDuration
                    durationSec = maxDuration - startTimeSec;
                end

                onsetBeats = startTimeSec / (60/melodyTempo);
                durationBeats = durationSec / (60/melodyTempo);

                melodyNmat = [melodyNmat; [onsetBeats, durationBeats, 1, pitch, velocity, startTimeSec, durationSec]];
            end
            currentTime = currentTime + melodyTotalDuration;
        end
        nmat = [nmat; melodyNmat];
    end

    if ~isempty(harmonySequence)
        % Determine the number of chord notes by checking non-zero values in the first row
        firstRow = harmonySequence(1, :);
        noteColumns = find(firstRow(1:end-3) ~= 0, 1, 'last'); % -3 to exclude duration, velocity, startTime

        if isempty(noteColumns)
            noteColumns = 3; % Default to triad if no non-zero notes found
        else
            noteColumns = min(7, noteColumns); % Limit to 7 notes per chord
        end

        harmonyNmat = [];
        currentTime = 0;
        while currentTime < maxDuration
            numChords = size(harmonySequence, 1);
            chordStartTimes = zeros(numChords, 1);
            chordStartTimes(1) = currentTime;
            for i = 2:numChords
                chordStartTimes(i) = chordStartTimes(i-1) + harmonySequence(i-1, 4);
            end
            for i = 1:numChords
                if chordStartTimes(i) >= maxDuration
                    continue;
                end
                chordDurationSec = harmonySequence(i, 4);
                if chordStartTimes(i) + chordDurationSec > maxDuration
                    chordDurationSec = maxDuration - chordStartTimes(i);
                end
                chordVelocity = harmonySequence(i, 5);

                % Process each note in the chord
                for j = 1:noteColumns
                    pitch = harmonySequence(i, j);
                    if pitch == 0
                        continue; % Skip placeholder zeros
                    end
                    onsetBeats = chordStartTimes(i) / (60/harmonyTempo);
                    durationBeats = chordDurationSec / (60/harmonyTempo);
                    harmonyNmat = [harmonyNmat; [onsetBeats, durationBeats, 2, pitch, chordVelocity, chordStartTimes(i), chordDurationSec]];
                end
            end
            currentTime = currentTime + harmonyTotalDuration;
        end
        nmat = [nmat; harmonyNmat];
    end

    % Add snare pattern if drum is detected
    try
        load('drumDetector.mat', 'detector');
        img = imread('lastUploadedImage.png');
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        end

        [bboxes, scores, labels] = detect(detector, img);

        disp('YOLOv3 Detection Results:');
        disp(labels);
        disp(scores);

        % Detect drum
        drumIdx = strcmpi(cellstr(labels), 'drum') & scores > 0.1;
        if any(drumIdx)
            disp('Drum detected! Adding snare pattern...');

            drumPattern = [];
            % Kick and snare melody 
            patternBeats = [0, 0.5, 1.0, 1.25, 1.5];
            patternNotes = [36, 38, 36, 36, 38];
            patternVelocity = [70, 85, 70, 70, 85];
            patternDuration = 0.2;

            % Hi-hat melody
            hihatPatternBeats = [0, 0.5, 1.0, 1.5];
            hihatNote = 42;
            hihatVelocity = 45;

            % Loop pattern across the track duration (every 2 seconds)
            for t = 0:2:(maxDuration - patternDuration)
                % Add Kick and Snare
                for i = 1:length(patternBeats)
                    startTime = t + patternBeats(i);
                    if startTime >= maxDuration
                        break;
                    end
                    onsetBeats = startTime / (60/melodyTempo);
                    durationBeats = patternDuration / (60/melodyTempo);
                    drumPattern = [drumPattern; onsetBeats, durationBeats, 10, patternNotes(i), patternVelocity(i), startTime, patternDuration];
                end
                % Add Hi-Hats
                for j = 1:length(hihatPatternBeats)
                    startTime = t + hihatPatternBeats(j);
                    if startTime >= maxDuration
                        break;
                    end
                    onsetBeats = startTime / (60/melodyTempo);
                    durationBeats = patternDuration / (60/melodyTempo);
                    drumPattern = [drumPattern; onsetBeats, durationBeats, 10, hihatNote, hihatVelocity, startTime, patternDuration];
                end
            end

            nmat = [nmat; drumPattern];
        else
            disp('No drum detected — skipping drum pattern.');
        end
    catch ME
        warning(['Drum detection failed: ', ME.message]);
    end

    if ~isempty(nmat)
        nmat = sortrows(nmat, 1);
        writemidi(nmat, outputFilename, finalTempo);
        disp(['Successfully wrote MIDI file: ', outputFilename]);
        disp(['Total duration: ', num2str(maxDuration), ' seconds']);
        disp(['Melody original duration: ', num2str(melodyTotalDuration), ' seconds']);
        disp(['Harmony original duration: ', num2str(harmonyTotalDuration), ' seconds']);
        disp(['Melody tempo: ', num2str(melodyTempo), ' BPM']);
        disp(['Harmony tempo: ', num2str(harmonyTempo), ' BPM']);
        disp(['Final MIDI tempo: ', num2str(finalTempo), ' BPM']);
    else
        error('No melody or harmony data to write to MIDI');
    end
end

