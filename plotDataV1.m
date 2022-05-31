function [s_in] = plotData(s, fs_pot, fs_press, c1, c2)
% Eplanation of function 

%  Input/output variables:
%   - s: structure array containing information of all selected files
%   - fs: sampling frequency
%   - s_in: modified structure array containing information of all selected files


s_in  = s;


for iRow = 1:numel(s_in) % loop over rows, i.e. selected files
    %% Plot all data
    figure_handle = figure('units','normalized','outerposition',[0 0 1 1]);
    hold on; grid on;
        
    t_press = (0:numel(s_in(iRow).pres1_adj)-1)/(fs_press);
    t_pot = (0:numel(s_in(iRow).pot1_filtered)-1)/(fs_pot);

    h1 = subplot(4,1,1); plot(t_pot, s_in(iRow).pot1_filtered, '-k', 'LineWidth', 2); hold on; grid on;
    ylabel('Stimulation Voltage [AU]','FontSize', 10); title('High frequency stimulation signal')
    
    h2 = subplot(4,1,2); plot(t_pot, s_in(iRow).pot2_filtered, '-k', 'LineWidth', 2); hold on; grid on;
    ylabel('Stimulation Voltage [AU]','FontSize', 10); title('Low frequency stimulation signal')

    h3 = subplot(4,1,3); plot(t_press, s_in(iRow).pres1_adj, '-b', 'LineWidth', 1); hold on; grid on;
    ylabel('Pressure [cmH_2O]','FontSize', 10); title('Pressure 1')
    %ylim([0 100])
    
    h4 = subplot(4,1,4); plot(t_press, s_in(iRow).pres2_adj, '-b', 'LineWidth', 1); hold on; grid on;
    ylabel('Pressure [cmH_2O]','FontSize', 10); title('Pressure 2')
    xlabel('Time [s]', 'FontSize', 10)

    sgtitle(char(s_in(iRow).name), 'Interpreter','none')
    all_ha = findobj( figure_handle, 'type', 'axes', 'tag', '' );
    linkaxes( all_ha, 'x' );

    imname = strcat('Filtered_signals_', char(s_in(iRow).name), '.png');
    saveas(gcf, strcat('Figures\', imname))

end 