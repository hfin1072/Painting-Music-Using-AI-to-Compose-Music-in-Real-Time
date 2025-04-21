function [channelnotes, chordnotes] = processmidifile(filename)
    [nmat, mstr] = readmidi(filename);

    clear notesperchannel notessplit
    channel = 0;
    time = 0;
    notessplit = zeros(size(nmat, 1), size(nmat, 2));

    for f = 1:size(notessplit, 1)
        notessplit(f, :) = nmat(f, :);
        if notessplit(f, 1) < time
            channel = channel + 1;
        end
        time = notessplit(f, 1);
        notessplit(f, 3) = channel;
    end

    channels = unique(notessplit(:, 3));

    for f = 1:length(channels)
        notesperchannel{f} = getmidich(notessplit, channels(f));
    end

    startchannel = 1;
    numberofchannels = length(channels());
    
    for f = 1:length(notesperchannel)
        thischannel = notesperchannel{f};
        onset = thischannel(1, 1);
        newchannel{startchannel} = thischannel(1, :);
        counter = 0;
        numberofchannelsadded = 0;

        for i = 2:size(thischannel, 1)
            if onset == thischannel(i, 1)
                counter = counter + 1;
                if length(newchannel) < (startchannel + counter)
                    newchannel{startchannel + counter} = thischannel(i, :);
                else
                    newchannel{startchannel + counter}(end + 1, :) = thischannel(i, :);
                end
                newchannel{startchannel + counter}(end, 3) = numberofchannels + counter;
            else
                if counter > numberofchannelsadded
                    numberofchannelsadded = counter;
                end
                newchannel{startchannel}(end + 1, :) = thischannel(i, :);
                onset = thischannel(i, 1);
                counter = 0;
            end
        end
        if counter > numberofchannelsadded
            numberofchannelsadded = counter;
        end
        startchannel = startchannel + numberofchannelsadded + 1;
        numberofchannels = numberofchannelsadded;
    end

    % Ensure consistent 5-column format
    if isempty(newchannel)
        channelnotes = zeros(0, 5);
    else
        channelnotes = cell2mat(newchannel');
    end

    chordnotes = processmidifileforchords(nmat);
end
