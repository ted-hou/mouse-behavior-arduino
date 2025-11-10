%% Load some neuropixel data
eu = EphysUnit.load('\\research.files.med.harvard.edu\neurobio\Assad Lab\Lingfeng\Data\Units\TwoColor_SNr_SCRetro\ReverseInjection\SingleUnit_NonDuplicate_NonDrift_SNr_withTrials', waveforms=false, spikecounts=false, spikerates=false);

%% Split units by session
[uniqueExpNames, ia, ic] = unique({eu.ExpName});
exp(length(uniqueExpNames)) = struct(eu=[]);
for iExp = 1:length(uniqueExpNames)
    exp(iExp).eu = eu(ic==iExp);
end


%% Find lick trials, define pre-lick vs. baseline
close all

clc

clear hyperparams;
hyperparams.window.move = {[-0.5, 0], [-0.5, -0.2]};
hyperparams.window.baseline = {[-10, -1], [-10, -3]};
hyperparams.nTrialsForTraining = {20, 40};

score = zeros(length(exp), length(hyperparams.window.move), length(hyperparams.window.baseline), length(hyperparams.nTrialsForTraining));
for iHpMove = 1:length(hyperparams.window.move)
    for iHpBaseline = 1:length(hyperparams.window.baseline)
        for iHpNTrials = 1:length(hyperparams.nTrialsForTraining)
            fprintf("%i %i %i\n", iHpMove, iHpBaseline, iHpNTrials)
            clear params
            params.window.move = hyperparams.window.move{iHpMove};
            params.window.baseline = hyperparams.window.baseline{iHpBaseline};
            params.nTrialsForTraining = hyperparams.nTrialsForTraining{iHpNTrials};
            
            for iExp = 1:length(exp)
            
                lickTrials = exp(iExp).eu(1).Trials.Lick;
                nTrialsForTraining = min(length(lickTrials) - 1, params.nTrialsForTraining);
                
                [XTrain, yTrain] = getData(exp(iExp), lickTrials(1:nTrialsForTraining), params);
                mdl = fitlm(XTrain, yTrain);
                
              
                [XTest, yTest] = getData(exp(iExp), lickTrials(nTrialsForTraining+1:end), params);
                
                %
                yHatMove = mdl.predict(XTest(yTest==1, :));
                yHatBaseline = mdl.predict(XTest(yTest==0, :));
                
                % ax = axes(figure);
                % hold(ax, 'on')
                % histogram(ax, yHatMove, -1:0.02:2, FaceColor='blue', FaceAlpha=0.2, DisplayName='peri-lick')
                % histogram(ax, yHatBaseline, -1:0.02:2, FaceColor='red', FaceAlpha=0.2, DisplayName='baseline')
            
                % histogram(ax, yHatMove, 50, FaceColor='blue', FaceAlpha=0.2, DisplayName='peri-lick')
                % histogram(ax, yHatBaseline, 50, FaceColor='red', FaceAlpha=0.2, DisplayName='baseline')
            
                score(iExp, iHpMove, iHpBaseline, iHpNTrials) = sum(yHatMove > max(yHatBaseline)) ./ length(yHatMove);
            
            
                % xlabel('p(move), a.k.a., "y"')
                % ylabel('pdf')
                % title(ax, sprintf('%s (%i units), pTrialsWeCanStim=%g', exp(iExp).eu(1).ExpName, length(exp(iExp).eu), percentTrialsWeCanStim(iExp)), Interpreter='none')
                % legend(ax)
            end

            
        end
    end
end

function [X, y] = getData(exp, trials, params)
    moveEdges = [[trials.Stop] + params.window.move(1); [trials.Stop]  + params.window.move(2)];
    
    spikerateMove = zeros(length(trials), length(exp.eu));
    for iEu = 1:length(exp.eu)
        for iTrial = 1:length(trials)
            spikerateMove(iTrial, iEu) = histcounts(exp.eu(iEu).SpikeTimes, moveEdges(:, iTrial))./diff(moveEdges(:, iTrial));
        end
    end
    
    baselineEdges = [[trials.Stop] + params.window.baseline(1); [trials.Stop]  + params.window.baseline(2)];
    spikerateBaseline = zeros(length(trials), length(exp.eu));
    for iEu = 1:length(exp.eu)
        for iTrial = 1:length(trials)
            spikerateBaseline(iTrial, iEu) = histcounts(exp.eu(iEu).SpikeTimes, baselineEdges(:, iTrial))./diff(baselineEdges(:, iTrial));
        end
    end

    % Now we have x = spikerate, y = isInLickBin
    % We fit a linear model on this
    X = [spikerateBaseline; spikerateMove];
    y = [zeros(size(spikerateBaseline, 1), 1); ones(size(spikerateMove, 1), 1)];
end

%%
squeeze(mean(score, 1))

% It seems like move: [-0.5, 0], baseline: [-10, -1], nTrialsForTraining:
% 40 was best, but maybe 30 trials is also okay?
% hyperparams.window.move = {[-0.5, 0], [-1, 0], [-1, -0.5]};
% hyperparams.window.baseline = {[-4, -1], [-6, -1], [-10, -1], [-2, -1]};
% hyperparams.nTrialsForTraining = {10, 20, 30, 40};

% val(:,:,1) =
% 
%       0.17268      0.14481      0.20475      0.12493
%      0.043247     0.063522      0.11722     0.029621
%      0.064869      0.10426      0.12456     0.021081
% 
% 
% val(:,:,2) =
% 
%       0.19173      0.18468      0.21091       0.1566
%      0.075679      0.10962      0.13818     0.048315
%      0.089536       0.1221      0.12834     0.046452
% 
% 
% val(:,:,3) =
% 
%       0.35659      0.33452      0.42751      0.31494
%       0.11291      0.15485      0.21791     0.099221
%       0.13075      0.14126      0.23136       0.0685
% 
% 
% val(:,:,4) =
% 
%       0.49303        0.489      0.49381      0.43927
%       0.21745      0.20117      0.23968      0.10283
%       0.14724      0.18589      0.22678     0.060792

