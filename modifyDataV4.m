function [s_in, fs_new] = modifyData(s, c1, c2, ds_fact, fs_press, fs_org , f_filt, blocks_pot1, blocks_pot2, press1, press2)
%MODIFYDATA Adjust pressure data to true values and possible filter signal
%   Input/output variables
%   - s: structure array containing information of all selected files
%   - c: calibration constant for pressure, input varies per rat
%   - ds_fact: data downsampling factor
%   - fs_org: original sampling frequency
%   - f_filt: cutoff frequency for lowpass pressure filter
%   - blocks_pot: number of stimulation blocks per stimulation signal
%   - press1: is 1 if pressure signal one is analyzed, otherwise 0

%   - s_in: new structure array containing information of all selected files
%   - fs_new: downampled sample frequency


s_in = s;                       % Work with copy of input array

%% Variables
au = 10;                                % Conversion factor AU --> cmH2O
fs_new = fs_org / ds_fact;              % Calculate samplerate of downsampled data
fs_new_press = fs_press / ds_fact;
name1 = 'pres1_adj';
name2 = 'pres2_adj';
name3 = 'pot1_filtered';
name4 = 'pot2_filtered';


for iRow = 1:numel(s_in)        % loop over rows, i.e. selected files
    potential1 = s_in(iRow).potential1;
    potential2 = s_in(iRow).potential2;
    pressure1 = s_in(iRow).pressure1;
    pressure2 = s_in(iRow).pressure2;
    
    %% Sometimes, an onset in the signals disrupts the analysis. 
    % Therefor, this onset is firstly detected in the pressure data and 
    % then removed from the data. 
    if press1 ~ 0;
        [s1,f1,ts1,p1] = spectrogram(pressure1, hann(200), 10, [], fs_press, 'yaxis');
        % Try to find the onset
        try 
            ipt_start = findchangepts(p1, 'MinThreshold',1e12);
        end 
    
        if ~isempty(ipt_start)
            potential1 = potential1((ts1(ipt_start)+1)*fs_org:end);
            potential2 = potential2((ts1(ipt_start)+1)*fs_org:end);
            pressure1 = pressure1((ts1(ipt_start)+1)*fs_org:end);
            pressure2 = pressure2((ts1(ipt_start)+1)*fs_org:end);
        end 
    else
        [s1,f1,ts1,p1] = spectrogram(pressure2, hann(200), 10, [], fs_press, 'yaxis');
        % Try to find the onset
        try 
            ipt_start = findchangepts(p1, 'MinThreshold',1e12);
        end 
    
        if ~isempty(ipt_start)
            potential1 = potential1((ts1(ipt_start)+1)*fs_org:end);
            potential2 = potential2((ts1(ipt_start)+1)*fs_org:end);
            pressure1 = pressure1((ts1(ipt_start)+1)*fs_org:end);
            pressure2 = pressure2((ts1(ipt_start)+1)*fs_org:end);
        end 
    end

    %% Filter out any power line artefacts (netspanning).
    % Apply a notch filter at 50 Hz.
    % The Notch filter is very narrowly designed, to avoid overlap with low
    % frequency stimulation.
    net_filter = designfilt('bandstopiir','FilterOrder',2, ...                       % create notch filter for 50 Hz (48-52 Hz)
                           'HalfPowerFrequency1',49.9,'HalfPowerFrequency2',50.1, ...
                           'DesignMethod','butter','SampleRate',fs_new);
    %fvtool(net_filter, 'FS', fs_new)                                       % Visualize the filter       
    potential1_filtered = filtfilt(net_filter, potential1);
    potential2_filtered = filtfilt(net_filter, potential2);
    pressure1_filtered = filtfilt(net_filter, pressure1);
    pressure2_filtered = filtfilt(net_filter, pressure2);

    %% Lowpass filter on pressure data
    % Apply a lowpass filter on the pressure data to fiter out signal
    % contamination from potential signals. 
    [b,a]=butter(4,f_filt/(0.5*fs_new_press));             
    pressure_filt1 = filtfilt(b,a,pressure1_filtered);     
    pressure_filt2 = filtfilt(b,a,pressure2_filtered);
    %% Filter on potential data
    %Highpass filter over potential 1.
    fc = 100;                                               % Cutoff frequency
    w = 2*pi*fc;                                            % Convert to randians per second
    fn = fs_new / 2;                                        % Nyguivst frequency
    [b,a]=butter(6,(w/fn), 'high');             
    potential_filt1 = filtfilt(b,a,potential1_filtered); 
    % Lowpass filter over potential 2. 
    fc = 30;
    w = 2*pi*fc;
    [b,a]=butter(6,(w/fn), 'low');             
    potential_filt2 = filtfilt(b,a,potential2_filtered);

    
    %% Downsampling
    pressure_filt_ds1 = downsample(pressure_filt1, ds_fact);                % you may want to downsample to improve calculation time of script
    pressure_filt_ds2 = downsample(pressure_filt2, ds_fact);

    %% Name new data 
    s_in(iRow).(name1) = ( pressure_filt_ds1 - c1 ) / au;                   % true pressure value is value minus calibration constant, then divided by the conversion factor
    s_in(iRow).(name2) = ( pressure_filt_ds2 - c2 ) / au;                   % true pressure value is value minus calibration constant, then divided by the conversion factor
    s_in(iRow).(name3) = ( potential_filt1 - c1 ) / au;                  % true pressure value is value minus calibration constant, then divided by the conversion factor
    s_in(iRow).(name4) = ( potential_filt2 - c2 ) / au;                  % true pressure value is value minus calibration constant, then divided by the conversion factor
end
    %% Make the signal flat if it not used
    if blocks_pot1 == 0;
        s_in(iRow).pot1_filtered = zeros(length(s_in(iRow).pot1_filtered),1);
    end 

    if blocks_pot2 ==0;
        s_in(iRow).pot2_filtered = zeros(length(s_in(iRow).pot2_filtered),1);
    end 

    if press1 == 0;
        s_in(iRow).pres1_adj = zeros(length(s_in(iRow).pres1_adj),1);
    end 

    if press2 ==0;
        s_in(iRow).pres2_adj = zeros(length(s_in(iRow).pres2_adj),1);
    end 


end

