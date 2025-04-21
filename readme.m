% to run the files you will need to add *this* directory to the path within
% Matlab, and also the miditoolbox directory that is a sub-folder of this
% one

% once you have added these to the path, change your directory to a folder
% containing the .midi files that you want to process, and then run
% 'runmidianalysis.m' which is a script file that will process the midi
% files.

% the output matrices pchords and pnotes contain the Markov Chain
% probabilities of each note, which can then be used for music generation