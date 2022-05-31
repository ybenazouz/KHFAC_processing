function [stim_block, freq] = getTimes(potential, blocks, ts, ipt, fs_pot)

    stim_block = zeros(length(blocks), 2);

    for i=1:2:2*blocks
        tstart  = ts(ipt(i));
        tend    = ts(ipt(i+1));
        stim = potential(fs_pot*tstart:fs_pot*tend);  
        % Use a fft in calcFreq to find the frequency in the stimulation
        % interval.
        freq = calcFreqV1(stim, fs_pot);
        stim_block(i,:) = [tstart tend];
    end 

end 

