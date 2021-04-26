function fit_results = psychFit(deltaBins, numR, numL, choices)

    %% Compute trials where the animal went right vs. evidence strength
    numRight            = zeros(numel(deltaBins),1);
    numTrials           = zeros(numel(deltaBins),1);
    trialDelta          = zeros(numel(deltaBins),1);
    nCues_RminusL       = numR - numL;
    trialBin            = binarySearch(deltaBins, nCues_RminusL, 0, 2);
    for iTrial = 1:numel(choices)
        numTrials(trialBin(iTrial))   = numTrials(trialBin(iTrial)) + 1;
        if choices(iTrial) == 2
            numRight(trialBin(iTrial))  = numRight(trialBin(iTrial)) + 1;
        end
        trialDelta(trialBin(iTrial))  = trialDelta(trialBin(iTrial)) + nCues_RminusL(iTrial);
    end
    trialDelta          = trialDelta ./ numTrials;


    %% Logistic function fit
    [phat, pci]          = binointerval(numRight, numTrials, normcdf(-1));
    sigmoid             = @(O,A,lambda,x0,x) O + A ./ (1 + exp(-(x-x0)/lambda));
    sel                 = numTrials > 0;

    if sum(sel) < 5
        psychometric      = [];
    else
        psychometric      = fit ( deltaBins(sel), phat(sel), sigmoid                      ...
                                , 'StartPoint'      , [0 1 8 0]                           ...
                                , 'Weights'         , ((pci(sel,2) - pci(sel,1))/2).^-2   ...
                                , 'MaxIter'         , 400                                 ...
                                );
    end
    pci(:,end+1)        = nan;
    delta               = linspace(deltaBins(1)-2, deltaBins(end)+2, 50);

    %% Draw a line with error bars for data
    errorX              = repmat(trialDelta(sel)', 3, 1);
    errorY              = pci(sel,:)';

    fit_results.delta_data      = trialDelta(sel)';
    fit_results.pright_data     = 100*phat(sel)';
    fit_results.delta_error     = errorX(:)';
    fit_results.pright_error    = 100*errorY(:)';

    if ~isempty(psychometric)
        fit_results.delta_fit = delta';
        fit_results.pright_fit = psychometric(delta)*100;
    else
        fit_results.delta_fit = [];
        fit_results.pright_fit = [];
    end
   
