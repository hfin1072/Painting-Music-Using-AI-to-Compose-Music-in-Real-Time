function [adjustedNote, predictedOctave] = filterNoteToScale(note, scaleType)
    % Define Major and Minor scales including flat keys
    allScales = struct(...
        'Major', [...  
            0  2  4  5  7  9 11;  % C Major
            2  4  6  7  9 11  1;  % D Major
            4  6  8  9 11  1  3;  % E Major
            5  7  9 10  0  2  4;  % F Major
            7  9 11  0  2  4  6;  % G Major
            9 11  1  2  4  6  8;  % A Major
            11 1  3  4  6  8 10;  % B Major
            1  3  5  6  8 10  0;  % Db Major
            3  5  7  8 10  0  2;  % Eb Major
            6  8 10 11  1  3  5;  % Gb Major
            8 10  0  1  3  5  7;  % Ab Major
            10 0  2  3  5  7  9;  % Bb Major
        ],...
        'Minor', [...  
            5  7  8 10  0  1  3;  % F Minor
            7  9 10  0  2  3  5;  % G Minor
            9 11  0  2  4  5  7;  % A Minor
            11 1  2  4  6  7  9;  % B Minor
            0  2  3  5  7  8 10;  % C Minor
            2  4  5  7  9 10  0;  % D Minor
            4  6  7  9 11  0  2;  % E Minor
            1  3  4  6  8  9 11;  % Db Minor
            3  5  6  8 10 11  1;  % Eb Minor
            6  8  9 11  1  2  4;  % Gb Minor
            8 10 11  1  3  4  6;  % Ab Minor
            10 0  1  3  5  6  8;  % Bb Minor
        ]...
    );

    % Use the predefined scale type
    if strcmp(scaleType, 'Major')
        scalePattern = allScales.Major;
    elseif strcmp(scaleType, 'Minor')
        scalePattern = allScales.Minor;
    else
        error('filterNoteToScale: Invalid scale type. Expected "Major" or "Minor".');
    end
    
    % Keep the predicted note as the root note
    rootNote = mod(note, 12);
    scaleNotes = mod(rootNote + scalePattern, 12);
   
    predictedOctave = floor(note / 12);
    
    % If the note is in the scale, keep it
    if ismember(rootNote, scaleNotes)
        adjustedNote = note;
    else
        % Find the closest valid note in the scale
        [~, idx] = min(abs(scaleNotes - rootNote));
        closestNote = scaleNotes(idx);
        adjustedNote = (predictedOctave * 12) + closestNote; % Use predicted octave
    end
end