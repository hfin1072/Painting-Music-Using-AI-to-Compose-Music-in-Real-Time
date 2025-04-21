function harmonySOM = trainHarmonySOM(combinedHarmonyFeatures)
    % Validate input
    if isempty(combinedHarmonyFeatures)
        error('No harmony features available for SOM training.');
    end

    % Normalize only pitch, pitch std, duration (columns 1–4)
    combinedHarmonyFeatures(:, 1:4) = normalize(combinedHarmonyFeatures(:, 1:4));

    % Define SOM Grid
    dim = [20, 20];  % Reduce if training takes too long
    net = selforgmap(dim);

    % Configure with feature input
    net = configure(net, combinedHarmonyFeatures');
    net.IW{1} = rand(size(net.IW{1}));  % Random init
    net.b{1} = rand(size(net.b{1}));

    % Batch training
    net.trainFcn = 'trainbu';
    net.trainParam.lr = 0.003;
    net.trainParam.epochs = 300;
    net.trainParam.showWindow = false;

    % Train
    try
        net = train(net, combinedHarmonyFeatures');
        disp('SOM Training Successful!');
    catch ME
        error('SOM Training Failed: %s', ME.message);
    end

    % Fix duration range (column 4)
    trainedWeights = net.IW{1};
    trainedWeights(:, 4) = rescale(trainedWeights(:, 4), 0.1, 2);
    net.IW{1} = trainedWeights;

    % Final output
    harmonySOM = net;

    % Sanity print
    disp('SOM Duration Weights (1st 5):');
    disp(harmonySOM.IW{1}(1:5, 4));

    % Generate and save SOM Weight Distance Map (U-Matrix)
    figure;
    plotsomnd(harmonySOM);
    title('SOM Weight Distances (U-Matrix)');
    print('SOM_Weight_Distances', '-dpng');

    % Generate SOM Hits plot
    figure;
    plotsomhits(harmonySOM, combinedHarmonyFeatures');
    title('SOM Hits');
    print('SOM_Hits','-dpng');   
end

function normVec = normalize(vec)
    normVec = (vec - min(vec)) ./ max(1e-6, (max(vec) - min(vec)));
end
