function [baseline, baselinePercentiles] = getBaselineFromStim(data, stim, sampleRate, baselineDuration, baselineOffset, percentiles)
%GETBASELINEFROMSTIM Summary of this function goes here
%   Detailed explanation goes here
baselineDuration = 10e-3;
baselineOffset = 0.5e-3;

baselineSamples = round(baselineDuration * sampleRate):-1:1;
baselineSamples = baselineSamples + round(baselineOffset * sampleRate);

baselineVector = zeros(length(stim), length(baselineSamples));

for idx=1:length(stim)
    baselineVector(idx, :) = data(stim(idx) - baselineSamples);
end

baselineVector = reshape(baselineVector', 1, []);

baseline = median(baselineVector);
baselinePercentiles = prctile(baselineVector, percentiles);
end

