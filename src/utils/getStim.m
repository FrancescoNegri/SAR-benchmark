function [stim, blankingNSamples] = getStim(blockObj)
%GETSTIM Summary of this function goes here
%   Detailed explanation goes here
stimPath = fullfile(blockObj.Output, blockObj.Name, 'StimData', 'Stim_Stim_Events.mat');
stim = load(stimPath);
stim = double(stim.data(2:end, :));

blankingNSamples = double(stim(:, 11));
stimChannelId = unique(stim(:, 2));

if length(stimChannelId) > 1
    stimChannelId = stimChannelId(1);
    warning('SFA:MultipleStimulatedChannels', 'There are multiple channels which are stimulated. Selected channel: %d', stimChannelId);
end

stimDuration = stim(stim(:, 2) == stimChannelId, 6);
stimDuration = round(stimDuration * blockObj.SampleRate);

stimOn = stim(stim(:, 2) == stimChannelId, 4);
stimOn = round(stimOn * blockObj.SampleRate);

stimOff = stimOn + stimDuration;

stim = struct('Onset', stimOn', 'Offset', stimOff');

end