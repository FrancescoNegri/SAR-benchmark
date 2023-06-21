function [crossCorr, x] = computeCrossCorr(reference, target, tau, windowNSamples)
    nMax = floor(windowNSamples/tau);

    crossCorr = zeros(2, nMax + 1);

    for n=1:size(crossCorr, 2)
        nullArray = zeros(1, (n-1) * tau);
    
        referencePos = [reference, nullArray];
        targetPos = [nullArray, target];

        referenceNeg = [nullArray, reference];
        targetNeg = [target, nullArray];

        crossCorr(1, n) = sum(and(targetPos, referencePos));
        crossCorr(2, n) = sum(and(targetNeg, referenceNeg));
    end

    crossCorr = [flip(crossCorr(2, 2:end)), crossCorr(1, 1:end)];
    crossCorr = crossCorr / sqrt(sum(reference) * sum(target));

    x = -windowNSamples:tau:windowNSamples;
end

