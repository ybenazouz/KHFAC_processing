function [s, dir_outp] =load_files(dir_import, dir_export)
%LOAD_FILES: file selection and data extraction - Via user interface one or multiple files can be selected.
%   Input/output variables:
%   - dir_import: the pre-set directory the user interface opens for data file selection
%   - dir_export: the pre-set directory the user interface opens for export directory selection
%   - s: structure array containing information of all selected files
%   - dir_output: export directory selected via user interface

[filename,path] = uigetfile('*.*',...                   % Opens user interface to select files
    'Select one or more files to IMPORT', ...
    dir_import, ...
    'MultiSelect', 'on');

filename_cell = cellstr(filename);                      % Force name into cell structure. So when only one file is selected, filename_cell(1) does refer to the first filename, instead of the first character of the string.

filepath = cellstr(fullfile(path, filename));           % Ensure output of cell array of character vectors
dir_outp = uigetdir(dir_export, 'Select OUTPUT directory');

%% Display selected files in command window
if isequal(filename,0)
   error('File selection canceled');
elseif length(filepath) == 1
    disp('File selected: '), disp(filename)
elseif length(filepath) > 1
    disp('Files selected: '), disp(filename)
end

%% Import data
for i = 1:length(filepath)
 s(i).name = string(filename_cell(i));
 data_file = importdata(string(filepath(i)));
 s(i).data = data_file;                                 % Read data and place it into structure

 %%
 s(i).pressure1 = data_file.pressure(:,1);
 s(i).pressure2 = data_file.pressure(:,2);
 s(i).potential1 = data_file.stimulation(:,1);
 s(i).potential2 = data_file.stimulation(:,2);

end

end 