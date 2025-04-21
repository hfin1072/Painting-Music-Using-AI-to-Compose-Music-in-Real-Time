function chordOffsets = generateChordOffsets(neuronIndex, chordSize)
% Map SOM neuron index to chord intervals (offsets from root pitch)
% Ensures non-repeating chords with fixed number of notes (chordSize)

    % Seed the RNG for consistent variation per neuron
    rng(neuronIndex);

    % Define a pool of common musical interval sets (extensions)
    chordPool = {
        [0 4 7],          % Major
        [0 3 7],          % Minor
        [0 4 7 11],       % Major 7
        [0 3 7 10],       % Minor 7
        [0 4 7 10],       % Dominant 7
        [0 3 6 10],       % Half-diminished 7
        [0 3 6 9],        % Diminished 7
        [0 5 7],          % Suspended 4
        [0 2 7],          % Suspended 2
        [0 4 8],          % Augmented triad
        [0 3 7 11 14],    % Minor 9
        [0 4 7 11 14],    % Major 9
        [0 4 7 10 13],    % Dominant 13
        [0 3 7 10 14],    % Minor 11
        [0 2 5 9 12]      % Colorful sus
    };

    % Shuffle the pool and pick one based on neuronIndex
    shuffled = chordPool(randperm(length(chordPool)));

    % Loop until finding a set of the right length
    for k = 1:length(shuffled)
        candidate = shuffled{k};
        if length(candidate) >= chordSize
            chordOffsets = candidate(1:chordSize);
            return;
        end
    end

    % Fallback: take from a generated pattern if no match found
    chordOffsets = sort(randsample(1:12, chordSize));
end
