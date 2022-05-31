function [ctr_start, pk_locs, duration, height, slope, miction] = calcContractions(pressure, fs_press, start_stimulation, end_stimulation, t_press, name)
% Detect contractions are calculate outcome measures per conctraction. 
% INPUT
%   - pressure: pressure signal
%   - fs: sampling frequency
%   - start_stimulation: start time of stimulation interval in seconds
%   - end_stimulation: end time of stimulation interval in seconds
%   - t_press: time array
%   - name: name of analyzed signal
% OUTPUT
%   - ctr_start: matrix with contraction onset times and labels (before,
%                during, after stimulation)
%   - pk_locs: timepoints of peaks in seconds
%   - duration: array with duration in seconds per contraction
%   - height: array with height in cmH2O per contraction
%   - slope: array with slope per contraction
%   - miction: array with label 1 for miction and 0 for now miction per
%              contraction


     % Find all peaks (contractions) in the pressure signal
     pressure_peaks = smoothdata(pressure,'SmoothingFactor', 0.01);
     [pks_max_all, locs_max_all] = findpeaks(pressure_peaks, fs_press, 'MinPeakDistance', 5, 'MinPeakProminence',1);

     % Find the valleys to determine the start and end times of the
     % contractions. 
     pressure_valleys = smoothdata(pressure,'SmoothingFactor', 0.0005);
     [pks_min, locs_min] = findpeaks(-pressure_valleys, fs_press, 'MinPeakDistance', 4, 'MinPeakProminence', 0.3);  
    
     % Remove peaks that occur in first and last second of signal
     a = find(locs_max_all < 1);
     b = find(locs_max_all > (t_press(end) - 1));
     locs_max_all(a) = [];
     locs_max_all(b) = [];
     pks_max_all(a) = [];
     pks_max_all(b) = [];

     % Remove incomplete contractions
     if locs_max_all(1) < locs_min(1);
        locs_max_all(1) = [];
        pks_max_all(1) = [];
        disp('First incomplete contractions removed')
     else 
        disp('No incomplete contractions removed at start') 
     end 

     if locs_max_all(end) > locs_min(end);
        locs_max_all(end) = [];
        pks_max_all(end) = [];
        disp('Last incomplete contraction removed')
     else 
        disp('No incomplete contractions removed at end ') 
     end 

     % Determine start times per contractions (based on the found peaks).
     ctr_start = zeros(length(pks_max_all),1);
     ctr_start_amp = zeros(length(pks_max_all),1);
     for i=1:length(pks_max_all)
           lower_locs = locs_min(find(locs_min < locs_max_all(i)));
           [~,idx]=min(abs(lower_locs-locs_max_all(i)));
           minVal=lower_locs(idx);
           ctr_start(i) = minVal;
     end 

       %% Plot data to change contraction startpoints
       t_press = (0:numel(pressure)-1)/(fs_press);
       x = zeros(length(ctr_start),1);
    
       for i=1:length(ctr_start)
            x(i) = t_press(round(ctr_start(i)*fs_press));
       end 
    
       figure; 
       h1 = plot(t_press, pressure, '-b', 'LineWidth', 1);
       set(gcf, 'Position',  [200, 200, 1000, 400])     % Set the size of the figure to make it more of a rectangular 
       hold on; h2 = xline(x, 'LineWidth',2);                 % Plot the onset of each contraction as a vertical line 
       h3 = xline(start_stimulation, '--');  h4 = xline(end_stimulation, '--');
       title(name); ylabel('Pressure [cmH_2O]','FontSize', 10);  xlabel('Time [s]', 'FontSize', 10); 
       %legend([h1 h2(1) h4], 'pressure', 'contraction onset','stimulation interval'); 
    
       % Now give a choise menu with 3 options, concerning the contractions
       %    1. Keep the contraction onset as calculated automatically
       %    2. Change the contraction onset if it is calculated incorrectly 
       %    3. Delete this contractions as a whole
        x_new = zeros(length(ctr_start),1);
        for i=1:size(ctr_start,1)
            xline(x(i), 'g', 'LineWidth',2)
            try
                xline(x(i-1), 'b', 'LineWidth',2)
            end 
            question = strcat('What do you want to do with the onset of contraction ', num2str(i),...
                ' of', name, '?  To keep all remaining onsets in one time, press X');
            answer = questdlg(question, ...
	            'Check contractions', ...
	            'Keep','Change', 'Delete', '');
            % Handle response
            switch answer
                case 'Keep'
                    x_new(i) = ctr_start(i,1);
                    xline(x(i), 'b', 'LineWidth', 1)
                case 'Change'
                    [xn, ~] = ginput(1); 
                    x_new(i) = xn;
                    xline(x(i), 'b', 'LineWidth', 1)
                    xline(x_new(i), 'b', 'LineWidth', 1)
                    message = strcat('Changed contraction', num2str(i));
                    disp(message)
                case 'Delete'
                    x_new(i) = 0;
                    %pks_max_all(i) = 0;
                    %locs_max_all(i) = 0;
                    xline(x(i), 'rx', 'LineWidth', 1)
                case ''
                    x_new(i:end) = ctr_start(i:end,1);
                    message = strcat('Kept contraction onsets from contraction ', num2str(i), ' onwards');
                    disp(message)
                    break 
            end    
        end 
        close

        % The new start times are
        ctr_start = x_new;
        rmv = find(ctr_start==0);
        ctr_start(rmv) = [];
        pks_max_all(rmv) = [];
        locs_max_all(rmv) = [];
    
       %% Add contractions that were not detected
       % First plot the figure with the changed contraction onsets. 
       figure;
       plot(t_press, pressure, '-b', 'LineWidth', 1);
       set(gcf, 'Position',  [200, 200, 1000, 400])
       hold on; xline(x_new);                               % Plot the onset of each contractions
       title(name); ylabel('Pressure [cmH_2O]','FontSize', 10); xlabel('Time [s]', 'FontSize', 10);
    
       % Now you get the choice to add a contraction that was not detected. 
       % Both the onset and the peak have to be determined. 
       x_onset = zeros(10,1);
       pk_new = zeros(10,2);
       for i=1:length(x_onset)
           question = strcat('Do you want to add another contraction in ', name, '?');
                answer = questdlg(question, ...
	                'Add contraction', ...
	                'Yes','No', '');
                % Handle response
                switch answer
                    case 'Yes'
                        title('Select onset of contraction!');
                        [xn, ~] = ginput(1); 
                        x_onset(i) = xn;
                        xline(xn, '-', 'Onset');
                        title('Select peak of contraction!');
                        [xp, yp] = ginput(1);
                        pk_new(i,1) = xp;
                        pk_new(i,2) = yp;
                        xline(xp, '--', 'Peak');
                        msgbox('Contraction added','OK')
                        disp('Contraction added!')
                    case 'No'
                        message = sprintf('No more contractions added');
                        disp(message)
                        break 
                    case ''
                        message = sprintf('No more contractions added');
                        disp(message)
                        break 
                end    
            end 
            close

            onset_new = cat(1, ctr_start, nonzeros(x_onset));
            pks_new = cat(1, [pks_max_all]', nonzeros(pk_new(:,2)));
            locs_new = cat(1, [locs_max_all]', nonzeros(pk_new(:,1)));
            % Combine all in order to sort on time 
            combined_array = cat(2, onset_new, pks_new, locs_new);
            combined_array = sortrows(combined_array,1);
    
            % Give the new contraction and peak times the old names 
            ctr_start = combined_array(:,1);
            pks_max_all = combined_array(:,2);
            locs_max_all = combined_array(:,3);
            pk_locs = locs_max_all;                     % To export from the function back to calcOutcome for other calculations
    
            %% Determine if the contractions occur before, during or after the stimulation interval 
            % A new column is added with a to indicate
            %       1 for contractions before stimulation
            %       2 for contractions during stimulation
            %       3 for contractions after stimulation 
             stimulation_array = zeros(length(pks_max_all),1);
             for i=1:length(ctr_start)
                 if locs_max_all(i) < start_stimulation;
                     stimulation_array(i) = 1;
                 elseif locs_max_all(i) > start_stimulation && locs_max_all(i) < end_stimulation || ...
                         ctr_start(i) > start_stimulation && ctr_start(i) < end_stimulation;
                     stimulation_array(i) = 2;
                 else 
                     stimulation_array(i) = 3; 
                 end 
             end 
             ctr_start(:,2) = stimulation_array;
        %% Perform calculations 
        % Make empty arrays for results of calculations 
         locs_max_all(length(locs_max_all)+1) = 0;
         duration = zeros(size(ctr_start,1),1);
         height = zeros(size(ctr_start,1),1);
         slope = zeros(size(ctr_start,1),1);
         miction = zeros(size(ctr_start,1),1);
         for i=1:size(ctr_start,1)
               duration(i) = locs_max_all(i) - ctr_start(i,1);                          % Calculate during of contraction 
               height(i) = pks_max_all(i) - pressure(round(ctr_start(i,1)*fs_press));   % Calculate height of contractions
               slope(i) = height(i) / duration(i);                                      % Calculate slope of contraction in cmH2O per sec
               
               % Determine if the contraction is accompanied by miction 
               % Evaluate the signal at the peak until one second after that
               % same peak 
               sig_miction = pressure(round(locs_max_all(i)*fs_press):round((locs_max_all(i)+1)*fs_press));
               % Calculate the fft of this part of the signal 
               Y = fft(sig_miction);
               L = length(sig_miction);
               P2 = abs(Y/L);
               P1 = P2(1:L/2+1);
               P1(2:end-1) = 2*P1(2:end-1);
               f = fs_press*(0:(L/2))/L;
               % Find peaks of frequencies between 10 and 20 Hz to identify
               % miction 
               [~, loc] = findpeaks(P1, f, 'MinPeakHeight',0.5);
               loc = round(loc);
               % Only analyse frequencies between 5 and 20 Hz as this is
               % where the peak should occur
               freqs = 8:1:17;
               % If this peak is found, a 1 is assigned to this peak. 
               % If no miction is detected, a 0 is assigned to this peak. 
               c = sum(ismember(loc,freqs));
                   if c ~ 0;
                       miction(i) = 1;
                   else 
                       miction(i) = 0;
                   end 
         end 
end 
    
     
           
