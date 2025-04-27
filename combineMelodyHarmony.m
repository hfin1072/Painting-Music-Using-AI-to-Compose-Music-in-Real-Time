function combineMelodyHarmony(melodySequence, harmonySequence, outputFilename, melodyTempo, harmonyTempo)
%   melodySequence [startTime, note, duration, velocity]
%   harmonySequence [note1, note2, ..., duration, velocity, startTime]

% Default tempos
    if nargin<4 || isempty(melodyTempo)
        melodyTempo = 120;
    end
    if nargin<5 || isempty(harmonyTempo)
        harmonyTempo = melodyTempo;
    end
    finalTempo = round((melodyTempo + harmonyTempo)/2);

    % Initilise
    nmat = [];
    melodyTotalDuration = 0;
    harmonyTotalDuration = 0;

    % Melody duration
    if ~isempty(melodySequence)
        melEnds = melodySequence(:,1) + melodySequence(:,3);
        melodyTotalDuration = max(melEnds);
    end

    % Harmony duration
    if ~isempty(harmonySequence)
        durCol = size(harmonySequence,2) - 2;
        harmonyTotalDuration = sum(harmonySequence(:,durCol));
    end

    % Overall duration
    maxDuration = max(melodyTotalDuration, harmonyTotalDuration);

    % Build melody
    if ~isempty(melodySequence)
        melodyNmat = [];
        currentTime = 0;
        while currentTime < maxDuration
            for i = 1:size(melodySequence,1)
                st = melodySequence(i,1) + currentTime;
                d  = melodySequence(i,3);

                if st >= maxDuration
                    continue; 
                end

                if st + d > maxDuration
                    d = maxDuration - st; 
                end

                on    = st/(60/melodyTempo);
                du    = d /(60/melodyTempo);
                pitch = melodySequence(i,2);
                vel   = melodySequence(i,4);
                melodyNmat(end+1,:) = [on, du, 1, pitch, vel, st, d]; 
            end

            currentTime = currentTime + melodyTotalDuration;
        end

        nmat = [nmat; melodyNmat];
    end

    % Build harmony
    if ~isempty(harmonySequence)
        harmonyNmat = [];
        currentTime = 0;
        durCol = size(harmonySequence,2) - 2;
        velCol = size(harmonySequence,2) - 1;
        while currentTime < maxDuration
            starts = [currentTime; currentTime + cumsum(harmonySequence(1:end-1,durCol))];
            for i = 1:size(harmonySequence,1)
                st  = starts(i);
                d   = harmonySequence(i,durCol);
                if st >= maxDuration
                    continue; 
                end
                if st + d > maxDuration
                    d = maxDuration - st; 
                end

                on    = st/(60/harmonyTempo);
                du    = d /(60/harmonyTempo);
                vel   = harmonySequence(i,velCol);
                notes = harmonySequence(i,1:durCol-1);

                for p = notes(notes>0)
                    harmonyNmat(end+1,:) = [on, du, 2, p, vel, st, d]; 

                end
            end

            currentTime = currentTime + harmonyTotalDuration;
        end

        nmat = [nmat; harmonyNmat];
    end

    % Car detection using tiny-YOLOv4-COCO
    try
        persistent vehDet
        if isempty(vehDet)
            vehDet = yolov4ObjectDetector("tiny-yolov4-coco");
        end

        img = imread('MultiObject2 7.jpg'); % same as Markov script
        if size(img,3)==1
            img = repmat(img,1,1,3);
        end

        [bboxes, scores, labels] = detect(vehDet, img, "Threshold",0.5);
        disp('YOLOv4 Detections:'); disp(table(bboxes, scores, labels));

        isCar = labels=="car" & scores>0.5;
        if any(isCar)
            disp('Car detected! Adding drum pattern.');
            totalDur = maxDuration;
            drumPattern = [];
            patternBeats = [0, 0.5, 1.0, 1.25, 1.5];
            patternNotes = [36, 38, 36, 36, 38];
            patternVel = [70, 85, 70, 70, 85];
            patDur = 0.2;
            hihatBeats = [0, 0.5, 1.0, 1.5];
            hihatNote = 42;
            hihatVel = 45;

            % kick-snare
            for t = 0:2:(totalDur - patDur)
                for k = 1:numel(patternBeats)
                    st = t + patternBeats(k);
                    if st >= totalDur
                        break; 
                    end

                    on = st/(60/melodyTempo);
                    du = patDur/(60/melodyTempo);
                    drumPattern(end+1,:) = [on, du, 10, patternNotes(k), patternVel(k), st, patDur]; 
                end

                % high-hat
                for k = 1:numel(hihatBeats)
                    st = t + hihatBeats(k);
                    if st >= totalDur
                        break; 
                    end

                    on = st/(60/melodyTempo);
                    du = patDur/(60/melodyTempo);
                    drumPattern(end+1,:) = [on, du, 10, hihatNote, hihatVel, st, patDur]; 
                end
            end

            nmat = [nmat; drumPattern];
        else
            disp('No car detected; skipping drum pattern.');
        end

    catch ME
        warning('Vehicle detection failed: %s', ME.message);
    end

    % Final MIDI output
    if ~isempty(nmat)
        nmat = sortrows(nmat,1);
        writemidi(nmat, outputFilename, finalTempo);
        fprintf('Successfully wrote MIDI file: %s\n', outputFilename);
        fprintf('Total duration: %.2f seconds\n', maxDuration);
    else
        error('No melody or harmony data to write to MIDI');
    end
end


