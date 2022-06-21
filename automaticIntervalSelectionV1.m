function [s_in, start_stim, end_stim] = automaticIntervalSelection(s, fs_pot, fs_press, blocks_pot1, blocks_pot2, press1, press2)
% In this function, the stimulation intervals are determined. This is
% firstly done automatically, but can then be corrected by hand. 

%  INPUT
%   - s: structure array containing information of all selected files
%   - fs: sampling frequency
%   - blocks_pot1: number of high frequency stimulation blocks
%   - blocks_pot2: number of low frequency stimulation blocks
%   - press1: is 1 if pressure signal one is analyzed, otherwise 0
%   - press2: is 1 if pressure signal two is analyzed, otherwise 0
% OUTPUT
%   - s_in: modified structure array containing information of all selected files
%   - start_stim: start time of stimulation interval in seconds
%   - end_stim: end time of stimulation interval in seconds



s_in  = s;


for iRow = 1:numel(s_in) % loop over rows, i.e. selected files
    potential1 = s_in(iRow).pot1_filtered;
    potential2 = s_in(iRow).pot2_filtered;

    %% Find the high frequency stimulation intervals in potential 1
    % Use spectrogram and findchangepts combined to detect changes in
    % frequency. The number of points to be found is based on the number of
    % stimulation blocks that are applied. 
    if blocks_pot1 ~= 0
        [~,~,ts_pot1,p_pot1] = spectrogram(potential1, hann(200), 10, [], fs_pot, 'yaxis');
        if max(potential1) > 50 
            ipt_pot1 = findchangepts(p_pot1, 'MaxNumChanges', blocks_pot1*2);
            % Obtain the timepoints at which the frequency changes. 
            if (numel(ipt_pot1) > 0) == 1 
                [hf_stim_times, freq1] = getTimesV1(potential1, blocks_pot1, ts_pot1, ipt_pot1, fs_pot);
                s_in(iRow).hf_stimulation_frequency = freq1;
            else %full block of no stimulation
                ipt_pot1 = sort(randperm(length(ts_pot1),2)) ; 
                [hf_stim_times, freq1] = getTimesV1(potential1, blocks_pot1, ts_pot1, ipt_pot1, fs_pot);
                s_in(iRow).hf_stimulation_frequency = freq1;
            end
        else % no stimulation
            ipt_pot1 = sort(randperm(length(ts_pot1),2)) ; 
            [hf_stim_times, freq1] = getTimesV1(potential1, blocks_pot1, ts_pot1, ipt_pot1, fs_pot);
            s_in(iRow).hf_stimulation_frequency = freq1;
        end 
    else
        disp("No stimulation in potential 1")
        hf_stim_times = [];
    end

    
    %% Find the low frequnecy stimulation intervals in potential 2
    % If there is only low frequency stimulation, the two biggest changes
    % in the power spectral density of the signal are detected. 
    if blocks_pot2 == not(0) && blocks_pot1 == 0
        [~,~,ts_pot2,p_pot2] = spectrogram(potential2, hann(200), 10, [], fs_pot, 'yaxis');
        ipt_pot2 = findchangepts(p_pot2, 'MaxNumChanges', blocks_pot2*4);
        [lf_stim_times, freq2] = getTimesV1(potential2, blocks_pot2, ts_pot2, ipt_pot2, fs_pot);
        s_in(iRow).lf_stimulation_frequency = freq2;

    % If there is also high frequency stimulation, this can give a
    % disruption of the low frequency signal that could also be detected as
    % changes. Therefore, 4 changes are detected, and the first and last
    % are selected as stimulation interval. 
    elseif blocks_pot2 == not(0) && blocks_pot1==not(0)
        [~,~,ts_pot2,p_pot2] = spectrogram(potential2, hann(200), 10, 20, fs_press, 'yaxis');
         ipt_pot2 = findchangepts(pow2db(p_pot2), 'MaxNumChanges', blocks_pot2*4);         
        ipt_pot2 = [ipt_pot2(1) ipt_pot2(end)];
        [lf_stim_times, freq2] = getTimesV1(potential2, blocks_pot2, ts_pot2, ipt_pot2, fs_pot);
        s_in(iRow).lf_stimulation_frequency = freq2;
    else
        disp("No stimulation in potential 2")
        lf_stim_times = [];
    end 
    
%% Add start and end times 
  if blocks_pot1 ~= 0
     s_in(iRow).hf_startstim    = hf_stim_times(1);
     s_in(iRow).hf_stopstim    = hf_stim_times(2);
  end 

  if blocks_pot2 ~= 0
     s_in(iRow).lf_startstim    = lf_stim_times(1);
     s_in(iRow).lf_stopstim    = lf_stim_times(2);
  end 

    %% Determine starttime, endtime. 
    alltimes = sort([lf_stim_times, hf_stim_times]);
    start_stim = alltimes(1);
    end_stim = alltimes(end);

    %% Plot interval
    linewidth = 1.6; 

    figure_handle = figure('units','normalized','outerposition',[0 0 1 1]);
    hold on; grid on;

    t_press = (0:numel(s_in(iRow).pres1_adj)-1)/fs_press;
    t_pot = (0:numel(s_in(iRow).pot1_filtered)-1)/fs_pot;

    h1 = subplot(4,1,1); plot(t_pot, potential1, '-k', 'LineWidth', 2); hold on; grid on;
    ylabel('Stimulation Voltage [AU]','FontSize', 10); title('High frequency stimulation signal')
    % Plot start and end times of high-frequency stimulation as red. 
    if blocks_pot1 ~ 0;
        for i=1:blocks_pot1
            xline([s_in(iRow).hf_startstim s_in(iRow).hf_stopstim], 'LineWidth', linewidth, 'Color', 'r')
        end 
    end
 
    h2 = subplot(4,1,2); plot(t_pot, potential2, '-k', 'LineWidth', 2); hold on; grid on;
    ylabel('Stimulation Voltage [AU]','FontSize', 10); title('Low frequency stimulation signal') 
    % Plot start and end times of low-frequency stimulation as green
    if blocks_pot2 ~= 0
       xline([s_in(iRow).lf_startstim s_in(iRow).lf_stopstim], 'LineWidth', linewidth, 'Color', 'g')
    end

    h3 = subplot(4,1,3); plot(t_press, s_in(iRow).pres1_adj, '-b', 'LineWidth', 1); hold on; grid on;
    ylabel('Pressure [cmH_2O]','FontSize', 10); title('Pressure 1')
    if press1 ~ 0;
        if blocks_pot2 ~ 0;
            xline([s_in(iRow).lf_startstim s_in(iRow).lf_stopstim], 'LineWidth', linewidth, 'Color', 'g')
        end 
        if blocks_pot1 ~ 0 ;
            xline([s_in(iRow).hf_startstim s_in(iRow).hf_stopstim], 'LineWidth', linewidth, 'Color', 'r')
        end 
    end 

    h4 = subplot(4,1,4); plot(t_press, s_in(iRow).pres2_adj, '-b', 'LineWidth', 1); hold on; grid on;
    ylabel('Pressure [cmH_2O]','FontSize', 10); title('Pressure 2')
    xlabel('Time [s]', 'FontSize', 10)
    if press2 ~ 0;
        if blocks_pot2 ~ 0;
            xline([s_in(iRow).lf_startstim s_in(iRow).lf_stopstim], 'LineWidth', linewidth, 'Color', 'g')
        end 
        if blocks_pot1 ~ 0 ;
            xline([s_in(iRow).hf_startstim s_in(iRow).hf_stopstim], 'LineWidth', linewidth, 'Color', 'r')
        end 
    end 

    
    all_ha = findobj( figure_handle, 'type', 'axes', 'tag', '' );
    linkaxes( all_ha, 'x' );
    

    %% Check if you agree with the high frequency interval
    if blocks_pot1 ~ 0;
        question = strcat('Do you want to change the high frequency stimulation interval?');
                    answer = questdlg(question, ...
	                    'High frequency stimulation interval', ...
	                    'Yes','No', '');
                    % Handle response
                    switch answer
                        case 'Yes'
                             question = strcat('What do you want to change');
                                        answer = questdlg(question, ...
	                                    'High frequency stimulation interval', ...
	                                    'Start','End', 'Both', '');
                                         % Handle response
                                         switch answer
                                            case 'Start'   
                                                [start_hf, ~] = ginput(1); 
                                                xline(h1,start_hf, 'r', 'Start');
                                                stop_hf = s_in(iRow).hf_stopstim;
                                                s_in(iRow).hf_startstim    = start_hf;
                                             case 'End'
                                                 [stop_hf, ~] = ginput(1); 
                                                 xline(h1,stop_hf, 'r', 'End');
                                                 start_hf = s_in(iRow).hf_startstim;
                                                 s_in(iRow).hf_stopstim    = stop_hf;
                                             case 'Both'
                                                  [start_hf, ~] = ginput(1); 
                                                  xline(h1,start_hf, 'r','Start');
                                                  [stop_hf, ~] = ginput(1); 
                                                  xline(h1,stop_hf, 'r' ,'End');
                                                  s_in(iRow).hf_startstim    = start_hf;
                                                  s_in(iRow).hf_stopstim    = stop_hf;
                                         end 
                        case 'No'
                            start_hf = s_in(iRow).hf_startstim;
                            stop_hf = s_in(iRow).hf_stopstim;
                        case ''
                            start_hf = s_in(iRow).hf_startstim;
                            stop_hf = s_in(iRow).hf_stopstim;
                    end 
    else 
        start_hf = [];
        stop_hf = [];
    end 
   

    %% Check if you agree with the low frequency interval
    if blocks_pot2 ~ 0;
        question = strcat('Do you want to change the low frequency stimulation interval?');
        answer = questdlg(question, ...
	                    'Low frequency stimulation interval', ...
	                    'Yes','No', '');
                    % Handle response
                    switch answer
                        case 'Yes'
                             question = strcat('What do you want to change');
                             answer = questdlg(question, ...
	                                 'High frequency stimulation interval', ...
	                                 'Start','End', 'Both', '');
                              % Handle response
                             switch answer
                                case 'Start'   
                                    [start_lf, ~] = ginput(1); 
                                    xline(h2,start_lf, 'g', 'Start');
                                    stop_lf = s_in(iRow).lf_stopstim;
                                    s_in(iRow).lf_startstim   = start_lf;
                                 case 'End'
                                     [stop_lf, ~] = ginput(1); 
                                     xline(h2,stop_lf, 'g', 'End');
                                     start_lf = s_in(iRow).lf_startstim;
                                     s_in(iRow).lf_stopstim    = stop_lf;
                                 case 'Both'
                                      [start_lf, ~] = ginput(1); 
                                      xline(h2,start_lf, 'g', 'Start');
                                      [stop_lf, ~] = ginput(1); 
                                      xline(h2,stop_lf, 'g', 'End');
                                      s_in(iRow).lf_startstim    = start_lf;
                                      s_in(iRow).lf_stopstim    = stop_lf;
                             end 
                        case 'No'
                            start_lf = s_in(iRow).lf_startstim;
                            stop_lf = s_in(iRow).lf_stopstim;
                        case ''
                            start_lf = s_in(iRow).lf_startstim;
                            stop_lf = s_in(iRow).lf_stopstim;
                    end 
    else 
        start_lf = [];
        stop_lf = [];
    end 

    %% Make a plot with the corrected intervals. 
    alltimes = sort([start_hf, stop_hf, start_lf, stop_lf]);
    start_stim = alltimes(1);
    end_stim = alltimes(end);

    linewidth = 1.6; 

    figure_handle = figure('units','normalized','outerposition',[0 0 1 1]);
    hold on; grid on;

    t_press = (0:numel(s_in(iRow).pres1_adj)-1)/fs_press;
    t_pot = (0:numel(s_in(iRow).pot1_filtered)-1)/fs_pot;

    h1 = subplot(4,1,1); plot(t_pot, potential1, '-k', 'LineWidth', 2); hold on; grid on;
    ylabel('Stimulation Voltage [AU]','FontSize', 10); title('High frequency stimulation signal')
    % Plot start and end times of high-frequency stimulation as red. 
    if blocks_pot1 ~ 0;
        for i=1:blocks_pot1
            xline([s_in(iRow).hf_startstim s_in(iRow).hf_stopstim], 'LineWidth', linewidth, 'Color', 'r')
        end 
    end
 
    h2 = subplot(4,1,2); plot(t_pot, potential2, '-k', 'LineWidth', 2); hold on; grid on;
    ylabel('Stimulation Voltage [AU]','FontSize', 10); title('Low frequency stimulation signal') 
    % Plot start and end times of low-frequency stimulation as green
    if blocks_pot2 ~ 0;
       xline([s_in(iRow).lf_startstim s_in(iRow).lf_stopstim], 'LineWidth', linewidth, 'Color', 'g')
    end

    h3 = subplot(4,1,3); plot(t_press, s_in(iRow).pres1_adj, '-b', 'LineWidth', 1); hold on; grid on;
    ylabel('Pressure [cmH_2O]','FontSize', 10); title('Pressure 1')
    if press1 ~ 0;
        if blocks_pot2 ~ 0;
            xline([s_in(iRow).lf_startstim s_in(iRow).lf_stopstim], 'LineWidth', linewidth, 'Color', 'g')
        end 
        if blocks_pot1 ~ 0 ;
            xline([s_in(iRow).hf_startstim s_in(iRow).hf_stopstim], 'LineWidth', linewidth, 'Color', 'r')
        end 
    end 

    h4 = subplot(4,1,4); plot(t_press, s_in(iRow).pres2_adj, '-b', 'LineWidth', 1); hold on; grid on;
    ylabel('Pressure [cmH_2O]','FontSize', 10); title('Pressure 2')
    xlabel('Time [s]', 'FontSize', 10)
    if press2 ~ 0;
        if blocks_pot2 ~ 0;
            xline([s_in(iRow).lf_startstim s_in(iRow).lf_stopstim], 'LineWidth', linewidth, 'Color', 'g')
        end 
        if blocks_pot1 ~ 0;
            xline([s_in(iRow).hf_startstim s_in(iRow).hf_stopstim], 'LineWidth', linewidth, 'Color', 'r')
        end 
    end 

    
    all_ha = findobj( figure_handle, 'type', 'axes', 'tag', '' );
    linkaxes( all_ha, 'x' );
    
    imname = strcat('Intervals_', char(s_in(iRow).name), '.png');
    saveas(gcf, strcat('Figures\', imname))

end 
                                             
end


