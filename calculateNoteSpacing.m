function noteSpacing = calculateNoteSpacing(img)
    % Ensure input is grayscale
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    
    % Detect edges using Canny method
    edges = edge(img, 'Canny');
    
    % Calculate spacing as ratio of edges to total pixels
    noteSpacing = sum(edges(:)) / numel(edges);
    
    % Ensure the spacing is within reasonable bounds (0.1 to 1.0)
    noteSpacing = max(0.1, min(noteSpacing, 1.0));
end