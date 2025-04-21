function chordnotes = processmidifileforchords(nmat)

% Allow small timing variations (e.g., 0.02 sec) to still count as chords.
timeThreshold = 0.05; % Allow small variations in start time

% Get all unique start times and count occurrences
[starttimes, ~, ic] = unique(round(nmat(:,1),2)); 
n = histc(nmat(:,1), starttimes);

chordnotes = [];

for f = 1:length(n)
    if n(f) > 1
        % Find where these notes are played in the MIDI file
        notesplayed = find(abs(nmat(:,1) - starttimes(f)) < timeThreshold);

        % Extract pitches, durations, and velocities
        pitches = nmat(notesplayed, 4);
        durations = nmat(notesplayed, 2);
        velocities = nmat(notesplayed, 5);

        % Ensure at least 3 notes for triads
        if length(pitches) >= 3
            rootPitch = min(pitches); % Assume lowest note is root
            thirdNote = rootPitch + 4; % Default major third (adjusted later)
            fifthNote = rootPitch + 7; % Default perfect fifth
            
            % Adjust if minor third exists in played notes
            if any(pitches == rootPitch + 3)
                thirdNote = rootPitch + 3;
            end

            % Use actual duration & velocity from the lowest note
            duration = durations(1);
            velocity = velocities(1);

            % Construct chord structure
            chordData = [rootPitch, thirdNote, fifthNote, duration, velocity];
            chordnotes = [chordnotes; chordData];
        end
    end
end

end
