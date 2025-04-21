% Function to map image brightness to note duration
function noteDuration = mapBrightnessToDuration(imageBrightness)
    % Ensure the brightness is within the range [0, 1]
    if imageBrightness < 0 || imageBrightness > 1
        error('Image brightness must be between 0 and 1.');
    end
    
    % Map image brightness to note duration
    if imageBrightness >= 0 && imageBrightness < 0.2
        noteDuration = 4;  % Whole note (4 beat)
    elseif imageBrightness >= 0.2 && imageBrightness < 0.4
        noteDuration = 2;   % half note (2 beat)
    elseif imageBrightness >= 0.4 && imageBrightness < 0.6
        noteDuration = 1;     % Quarter note (1 beat)
    elseif imageBrightness >= 0.6 && imageBrightness < 0.8
        noteDuration = 0.5;     % Eight note(1/2 beats)
    elseif imageBrightness >= 0.8 && imageBrightness <= 1
        noteDuration = 0.25;     % Sixteenth note (1/4 beats)
    end
end
