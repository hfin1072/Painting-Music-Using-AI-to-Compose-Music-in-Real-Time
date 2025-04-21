function p = calculateProbabilityMatrix(x)
% This function calculates the transition probability matrix for MIDI notes.
% It considers the first state (column 1) and the next state (column 2).

% Ensure input is an integer
x = round(x);  

% MIDI notes range from 0 to 127, so we must map indices properly.
minNote = 0; % Minimum MIDI value
maxNote = 127; % Maximum MIDI value
numNotes = maxNote - minNote + 1; % Total possible notes (128)

% Ensure all values are in the valid range (0 to 127)
x(x < minNote | x > maxNote) = [];  

if isempty(x)
    warning('No valid MIDI notes found. Probability matrix will be empty.');
    p = zeros(numNotes, numNotes);
    return;
end

% Transition probability matrix initialization
p = zeros(numNotes, numNotes);
y = zeros(numNotes, 1);

% Map MIDI values to matrix indices (1-based)
x = x - minNote + 1;  

% Fill transition counts
n = numel(x);
for k = 1:n-1
    y(x(k)) = y(x(k)) + 1;
    p(x(k), x(k+1)) = p(x(k), x(k+1)) + 1;
end

% Normalize probabilities (each row sums to 1)
p = bsxfun(@rdivide, p, y);
p(isnan(p)) = 0;  % Replace NaNs with zero where no transitions occurred

end
