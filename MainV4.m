%% General Information
% Author: Max Ligtenberg, max.ligtenberg@outlook.com
% as product of Technical Medicine Internship June-August 2020
% 
% ErasmusMC, dept. Urology, group: functional Urology lab
% Written in MATLAB R2018b

% Edited Version
% Edited by: Bart Formsma, bartformsma@hotmail.com
% as product of Technical Medicine Internship September-November 2020
%
% Edited Version
% Edited by: Anne Meester, annemeester95@hotmail.com
% as product of Technical Medicine Internship September-November 2021
%
% Edited Version
% Edited by: Sabine Josemans, shjosemans@gmail.com
% as product of Technical Medicine Internship November 2021 - February 2022
% 
% Edited Version
% Edited by: Yasmin Ben Azouz, yasminbenazouz@hotmail.com
% as product of Technical Medicine Internship May 2022 - August 2022 
%
% ErasmusMC, dept. Urology, group: functional Urology lab
% Edited in MATLAB R2021b

close all; clear; %clc;

%% Variables
DIR_IMPORT = [];        % when desired, set a default directory to select files from, otherwise use = [];
DIR_EXPORT = [];        % when desired, set a default directory the OUTPUT directory user interface will open up, otherwise use = [];
mkdir 'Figures'
mkdir 'Calculations'
FS_POT = 60000;        % [Hz] sampling frequency
FS_PRESS = 60000;

%% Input values
% C = 5111;            % Calibration factor
% C = 5420;            % calibration factor 150420
% C = 5859.4;          % Calibration factor 040320
C_press1 = 0;          % Calibration factor 16022022 = 28725;
C_press2 = 0;

TX  = 4;                % Amount of seconds of which the declining pressure slope upon inhibition will be calculated (seconds after start inhibition)
DS_FACT = 2;            % Downsampling factor
F_FILT = 18;            % [Hz] low-pass filter frequency for pressure 

% Set the number of stimulation blocks for low-frequency and high-frequency separately 
HF_BLOCKS = 1;
LF_BLOCKS = 0;

% Determine which pressure channels you want to evaluate
PRESS1 = 0;
PRESS2 = 1;
             
%% Execute
[SData, DIR_EXPORT] = load_filesV3(DIR_IMPORT, DIR_EXPORT);
[SData_mod, FS_PRESS] = modifyDataV4(SData, C_press1, C_press2, DS_FACT, FS_PRESS, FS_POT, F_FILT, HF_BLOCKS, LF_BLOCKS, PRESS1, PRESS2);
%%
plotDataV1(SData_mod,FS_POT, FS_PRESS, C_press1, C_press2);
%%
[SData_auto, start_stim, end_stim] = automaticIntervalSelectionV1(SData_mod,FS_POT, FS_PRESS, HF_BLOCKS, LF_BLOCKS, PRESS1, PRESS2);
[SData_exp] = calcOutcomeV4(SData_auto, FS_POT, FS_PRESS, TX, HF_BLOCKS, LF_BLOCKS, PRESS1, PRESS2, start_stim, end_stim);
%%
exportFuncV4(SData_exp, DIR_EXPORT, PRESS1, PRESS2);

msgbox('Operation Completed','Success')
disp('Operation completed!')
