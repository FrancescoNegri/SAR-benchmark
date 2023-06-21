function filename = getRandomFilename(length)
%GETRANDOMFILENAME Summary of this function goes here
%   Detailed explanation goes here

symbols = ['a':'z', '0':'9'];
nums = randi(numel(symbols),[1, length]);
filename = symbols(nums);
end

