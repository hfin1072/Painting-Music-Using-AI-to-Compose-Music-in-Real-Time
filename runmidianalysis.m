%% load midi files in current directory
files=dir('*.mid');

for f=1:length(files)
    disp(['Processing file: ' files(f).name])
    [midifilenotes{f} midifilechords{f}]=processmidifile(files(f).name);
end
%% analyse notes
%now that we have the "melodies" separated, we can analyse the notes and
%their duration for each pitch separately
%for this want to build a matrix of the transition states

%so to analyse this, want to build a single vector of the "harmonies"
%initialise variable
allnotes=[];
allchords=[];
alldurations=[];
%go through all the midi files
for f=1:length(midifilenotes)
    %go through each "harmony" in each midi file
    channelstoanalyse=midifilenotes{f};
    for i=1:length(channelstoanalyse)
        %add notes to single vector
        notes=channelstoanalyse{i}(:,4);
        allnotes=[allnotes;notes;[128]];
    end
    
    %also add all chords to single matrix variable
    allchords=[allchords;midifilechords{f}];
    
    %also add all durations
end
%create probability matrix for all of these notes
pnotes=calculateProbabilityMatrix(allnotes);

%create probability matrix for all of these chords
pchords=calculateProbabilityMatrix(allchords);

%output variable p now holds the probabilty matrix for all notes in the
%analysed midi file