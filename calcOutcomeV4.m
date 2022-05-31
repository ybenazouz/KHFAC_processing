function [s_in] = calcOutcome(s,fs_pot,fs_press,tx, hf_blocks, lf_blocks, press1, press2, start_stim, end_stim)
% calcOutcome Calculates desired outcomes from selected windows and data

% INPUT
%   - s: structure array containing information of all selected files
%   - fs: sampling frequency
%   - tx: time of which the inhib pressure slope is calculated, in seconds
%   - hf_blocks: number of high frequency stimulation blocks
%   - lf_blocks: number of low frequency stimulation blocks
%   - press1: is 1 if pressure signal one is analyzed, otherwise 0
%   - press2: is 1 if pressure signal two is analyzed, otherwise 0
%   - start_stim: start time of stimulation interval in seconds
%   - end_stim: end time of stimulation interval in seconds
% OUTPUT
%   - s_in: modified structure array containing information of all selected files


s_in = s;   % work with copy of input array
tx(tx==0) = 1; % if tx=0, this value will later cause an error (cannot devide by 0). So if input tx equals 0, tx will be changed to 1.
slope_fieldname = sprintf('inhib_slope_for_%usec', tx);  % fieldname of slope that includes the amount of seconds it is calculated from


 for iRow = 1:numel(s_in)   % loop over rows, i.e. selected files
        pressure1 = s(iRow).pres1_adj';    % copy values, but with a simpler name
        pressure2 = s(iRow).pres2_adj';    % copy values, but with a simpler name
        potential1 = s(iRow).pot1_filtered';
        potential2 = s(iRow).pot2_filtered';

        t_press = (0:numel(s_in(iRow).pressure1)-1)/fs_press;

         name1 = ' pressure 1';
         s_in(iRow).p1.name = name1;
         name2 = ' pressure 2';
         s_in(iRow).p2.name = name2;
        

        %% Determine pressures at stimulation interval start and end times 
        % Determine the pressure values at start and end times of stimulation
        % intervals
        if lf_blocks ~ 0;
            s_in(iRow).p1.pressure_startstim_lf = pressure1(round(s_in(iRow).lf_startstim*fs_press));
            s_in(iRow).p1.pressure_stopstim_lf = pressure1(round(s_in(iRow).lf_stopstim*fs_press));
            s_in(iRow).p2.pressure_startstim_lf = pressure2(round(s_in(iRow).lf_startstim*fs_press));
            s_in(iRow).p2.pressure_stopstim_lf = pressure2(round(s_in(iRow).lf_stopstim*fs_press));
        end 
    
        if hf_blocks ~ 0;
            s_in(iRow).p1.pressure_startstim_hf = pressure1(round(s_in(iRow).hf_startstim*fs_press));
            s_in(iRow).p1.pressure_stopstim_hf = pressure1(round(s_in(iRow).hf_stopstim*fs_press));
            s_in(iRow).p2.pressure_startstim_hf = pressure2(round(s_in(iRow).hf_startstim*fs_press));
            s_in(iRow).p2.pressure_stopstim_hf = pressure2(round(s_in(iRow).hf_stopstim*fs_press));
        end 

         %% Contraction calculations of pressure 1
         if press1 ~ 0;
             % Use function calcContractions
             [ctr_start1, pk_locs1, duration, height, slope, miction] = calcContractionsV1(pressure1, ...
                 fs_press, start_stim, end_stim, t_press, name1);
             % Determine if contractions occur before, during or after
             % These labels are assigned in the function calcContractions
             % Before stimulation
            index1 = find(ctr_start1(:,2)==1);
            % During stimulation
            index2 = find(ctr_start1(:,2)==2);
            % After stimulation
            index3 = find(ctr_start1(:,2)==3);
            
            % Contractions per minute
            s_in(iRow).p1.contractions_per_min_before_stimulation = length(index1) / (start_stim - ctr_start1(index1(1),1)) * 60;
            s_in(iRow).p1.contractions_per_min_during_stimulation = length(index2) / (end_stim - start_stim) * 60;
    
            % Duration of contractions in seconds
            s_in(iRow).p1.duration_of_contractions_before_stimulation = mean(duration(index1));
            s_in(iRow).p1.duration_of_contractions_during_stimulation = mean(duration(index2));
            s_in(iRow).p1.duration_of_contractions_after_stimulation = mean(duration(index3));
            
            % Interval between contractions in seconds
            pks_ind1 = pk_locs1(index1);
            interval = zeros(length(pks_ind1),1);
            if length(pks_ind1) >= 2;
                for i=1:length(pks_ind1)
                    try
                    interval(i) = pks_ind1(i+1) - pks_ind1(i);
                    end 
                end 
                 s_in(iRow).p1.interval_between_contractions_before_stimulation = mean(nonzeros(interval));
            else
                s_in(iRow).p1.interval_between_contractions_before_stimulation = NaN;
            end 
    
            pks_ind2 = pk_locs1(index2);
            interval = zeros(length(pks_ind2),1);
            if length(pks_ind2) >= 2;
                for i=1:length(pks_ind2)
                    try
                    interval(i) = pks_ind2(i+1) - pks_ind2(i);
                    end 
                end 
                 s_in(iRow).p1.interval_between_contractions_during_stimulation = mean(nonzeros(interval));
            else
                s_in(iRow).p1.interval_between_contractions_during_stimulation = NaN;
            end 
    
            pks_ind3 = pk_locs1(index3);
            interval = zeros(length(pks_ind3),1);
            if length(pks_ind3) >= 2;
                for i=1:length(pks_ind3)
                    try
                    interval(i) = pks_ind3(i+1) - pks_ind3(i);
                    end 
                end 
                 s_in(iRow).p1.interval_between_contractions_after_stimulation = mean(nonzeros(interval));
            else
                s_in(iRow).p1.interval_between_contractions_after_stimulation = NaN;
            end 
    
            % Contraction heigth in cmH2O
            s_in(iRow).p1.contraction_height_before_stimulation = mean(height(index1));
            s_in(iRow).p1.contraction_height_during_stimulation = mean(height(index2));
            s_in(iRow).p1.contraction_height_after_stimulation = mean(height(index3));
    
            % Slope of contration in cmH2O/sec
            s_in(iRow).p1.slope_of_contraction_before_stimulation = mean(slope(index1));
            s_in(iRow).p1.slope_of_contraction_during_stimulation = mean(slope(index2));
            s_in(iRow).p1.slope_of_contraction_after_stimulation = mean(slope(index3));
    
            % Contraction with or without miction
            s_in(iRow).p1.contractions_with_miction_before_stimulation = sum(nonzeros(miction(index1)));
            s_in(iRow).p1.contractions_without_miction_before_stimulation = length(index1) - sum(nonzeros(miction(index1)));
            s_in(iRow).p1.contractions_with_miction_during_stimulation = sum(nonzeros(miction(index2)));
            s_in(iRow).p1.contractions_without_miction_during_stimulation = length(index2) - sum(nonzeros(miction(index2)));
            s_in(iRow).p1.contractions_with_miction_after_stimulation = sum(nonzeros(miction(index3)));
            s_in(iRow).p1.contractions_without_miction_after_stimulation = length(index3) - sum(nonzeros(miction(index3)));
        
            ctr_start1 = nonzeros(ctr_start1);
            ctr_start1 = reshape(ctr_start1, [],2);
         end 
        %% Contraction calculations of pressure 2
        if press2 ~ 0;
            % Use function calcContractions 
            [ctr_start2, pk_locs2, duration, height, slope, miction] = calcContractionsV1(pressure2, ...
                fs_press, start_stim, end_stim, t_press, name2);
            % Determine if contractions occur before, during or after
            % stimulation
            index1 = find(ctr_start2(:,2)==1);
            index2 = find(ctr_start2(:,2)==2);
            index3 = find(ctr_start2(:,2)==3);
            
            % Contractions per minute 
            s_in(iRow).p2.contractions_per_min_before_stimulation = length(index1) / (start_stim - ctr_start2(index1(1),1)) * 60;
            s_in(iRow).p2.contractions_per_min_during_stimulation = length(index2) / (end_stim - start_stim) * 60;
            
            % Duration of contractions in seconds
            s_in(iRow).p2.duration_of_contractions_before_stimulation = mean(duration(index1));
            s_in(iRow).p2.duration_of_contractions_during_stimulation = mean(duration(index2));
            s_in(iRow).p2.duration_of_contractions_after_stimulation = mean(duration(index3));
    
            % Interval between contractions in seconds
            pks_ind1 = pk_locs2(index1);
            interval = zeros(length(pks_ind1),1);
            if length(pks_ind1) >= 2;
                for i=1:length(pks_ind1)
                    try
                    interval(i) = pks_ind1(i+1) - pks_ind1(i);
                    end 
                end 
                 s_in(iRow).p2.interval_between_contractions_before_stimulation = mean(nonzeros(interval));
            else
                s_in(iRow).p2.interval_between_contractions_before_stimulation = NaN;
            end 
    
            pks_ind2 = pk_locs2(index2);
            interval = zeros(length(pks_ind2),1);
            if length(pks_ind1) >= 2;
                for i=1:length(pks_ind2)
                    try
                    interval(i) = pks_ind2(i+1) - pks_ind2(i);
                    end 
                end 
                 s_in(iRow).p2.interval_between_contractions_during_stimulation = mean(nonzeros(interval));
            else
                s_in(iRow).p2.interval_between_contractions_during_stimulation = NaN;
            end 
    
            pks_ind3 = pk_locs2(index3);
            interval = zeros(length(pks_ind3),1);
            if length(pks_ind3) >= 2
                for i=1:length(pks_ind3)
                    try
                    interval(i) = pks_ind3(i+1) - pks_ind3(i);
                    end 
                end 
                 s_in(iRow).p2.interval_between_contractions_after_stimulation = mean(nonzeros(interval));
            else
                s_in(iRow).p2.interval_between_contractions_after_stimulation = NaN;
            end 
            
            % Height of contractions in cmH2O
            s_in(iRow).p2.contraction_height_before_stimulation = mean(height(index1));
            s_in(iRow).p2.contraction_height_during_stimulation = mean(height(index2));
            s_in(iRow).p2.contraction_height_after_stimulation = mean(height(index3));
    
            % Slope of contractions cmH2O/sec
            s_in(iRow).p2.slope_of_contraction_before_stimulation = mean(slope(index1));
            s_in(iRow).p2.slope_of_contraction_during_stimulation = mean(slope(index2));
            s_in(iRow).p2.slope_of_contraction_after_stimulation = mean(slope(index3));
    
            % Contractions with or without miction 
            s_in(iRow).p2.contractions_with_miction_before_stimulation = sum(nonzeros(miction(index1)));
            s_in(iRow).p2.contractions_without_miction_before_stimulation = length(index1) - sum(nonzeros(miction(index1)));
            s_in(iRow).p2.contractions_with_miction_during_stimulation = sum(nonzeros(miction(index2)));
            s_in(iRow).p2.contractions_without_miction_during_stimulation = length(index2) - sum(nonzeros(miction(index2)));
            s_in(iRow).p2.contractions_with_miction_after_stimulation = sum(nonzeros(miction(index3)));
            s_in(iRow).p2.contractions_without_miction_after_stimulation = length(index3) - sum(nonzeros(miction(index3)));
        
            ctr_start2 = nonzeros(ctr_start2);
            ctr_start2 = reshape(ctr_start2, [],2);
        end 


        %% Plot data 
        % with markers at the onset (>) and peak (*) of contractions
        figure_handle = figure('units','normalized','outerposition',[0 0 1 1]);
        hold on; grid on;
    
        t_press = (0:numel(s_in(iRow).pres1_adj)-1)/(fs_press);
        t_pot = (0:numel(s_in(iRow).pot1_filtered)-1)/(fs_pot);
    
        h1 = subplot(4,1,1); plot(t_pot, potential1, '-k', 'LineWidth', 2); hold on; grid on;
        ylabel('Stimulation Voltage [AU]','FontSize', 10); title('Stimulation signal 1')
        
        h2 = subplot(4,1,2); plot(t_pot, potential2, '-k', 'LineWidth', 2); hold on; grid on;
        ylabel('Stimulation Voltage [AU]','FontSize', 10); title('Stimulation signal 2')
    
        h3 = subplot(4,1,3); plot(t_press, pressure1, '-b', 'LineWidth', 1); hold on; grid on;
        ylabel('Pressure [cmH_2O]','FontSize', 10); title('Pressure 1')
        if press1 ~ 0;
            for i=1:length(ctr_start1)
                plot(t_press(round(ctr_start1(i)*fs_press)), pressure1(round(ctr_start1(i)*fs_press)), '>', 'LineWidth',2)
                plot(t_press(round(pk_locs1(i)*fs_press)), pressure1(round(pk_locs1(i)*fs_press)), '*', 'LineWidth',2)
            end 
        end 
        
        h4 = subplot(4,1,4); plot(t_press, pressure2, '-b', 'LineWidth', 1); hold on; grid on;
        ylabel('Pressure [cmH_2O]','FontSize', 10); title('Pressure 2')
        if press2 ~ 0;
            for i=1:length(ctr_start2)
                plot(t_press(round(ctr_start2(i)*fs_press)), pressure2(round(ctr_start2(i)*fs_press)), '>', 'LineWidth',2)
                plot(t_press(round(pk_locs2(i)*fs_press)), pressure2(round(pk_locs2(i)*fs_press)), '*', 'LineWidth',2)
            end 
        end 
        xlabel('Time [s]', 'FontSize', 10)
    
        sgtitle('Contractions with onset (>) and peak (*)', 'Interpreter','none')
        all_ha = findobj( figure_handle, 'type', 'axes', 'tag', '' );
        linkaxes( all_ha, 'x' );
    
         saveas(gcf, strcat('Figures\Contractions')) 
         
  end
 

