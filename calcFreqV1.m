function [frequency] = calcFreq(s_short, fs_pot)
        Y = fft(s_short);
        L = length(s_short);
        P2 = abs(Y/L);
        P1 = P2(1:L/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        f = fs_pot*(0:(L/2))/L;

        % In the low frequency signal, there is a peak near 0 Hz. First
        % remove this filter and then determine the maximal peak to obtain
        % the frequency of this part of the signal. 
        [pks, loc] = findpeaks(P1, f, 'MinPeakDistance',10);
        remove_locs = find(loc<10);
        pks(remove_locs) = 0;
        frequency = round(loc(find(pks==max(pks))));


%         %Optional: plot fft
%         figure;
%         plot(f,P1) 
%         title('Single-Sided Amplitude Spectrum of X(t)')
%         xlabel('f (Hz)')
%         ylabel('|P1(f)|')   
end 