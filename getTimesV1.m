function [stim_block, freq] = getTimes(potential, blocks, ts, ipt, fs_pot)

    stim_block = zeros(length(blocks), 2);
    if (numel(ipt) == numel(stim_block)) == 1
        for i=1:2:2*blocks
            tstart  = ts(ipt(i));
            tend    = ts(ipt(i+1));
            stim = potential(fs_pot*tstart:fs_pot*tend);  
            % Use a fft in calcFreq to find the frequency in the stimulation
            % interval.
            freq = calcFreqV1(stim, fs_pot);
            stim_block(i,:) = [tstart tend];
        end 
    else % this always means that either a start or end has not been detected
        len = (2*blocks) - length(ipt) ; 
        add = zeros(len,1) ; 
        for ii = 1:len 
            add(ii,:)= ipt + ii ;
        end 
        ipt_add = [ipt add] ; 
        for i=1:2:2*blocks
            tstart  = ts(ipt_add(i));
            tend    = ts(ipt_add(i+1));
            stim = potential(fs_pot*tstart:fs_pot*tend);  
            % Use a fft in calcFreq to find the frequency in the stimulation
            % interval.
            freq = calcFreqV1(stim, fs_pot);
            stim_block(i,:) = [tstart tend];
        end 
    end 
end 

