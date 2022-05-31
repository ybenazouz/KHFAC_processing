function exportFunc(s, dir, press1, press2)
%EXPORTFUNC Exports the created data structure to an excel file
%   Input/output variables:
%   - s: structure array containing information of all selected files
%   - dir: desired output directory

s_in = s;

filename = sprintf('%s\\Stimulation information %s %s.xlsx', dir, s.name, datestr(now,'yyyy-mm-dd HH-MM-ss')); % state filename of the output file
filename_p = sprintf('%s\\Pressure calculations %s %s.xlsx', dir,s.name, datestr(now,'yyyy-mm-dd HH-MM-ss'));

%% Make structs with outcome measures the same size for both pressure signals
% This is necessary for exporting the data. 
if press1 == 0;
    s_in.p1 = [];
end 

if press2 == 0;
    s_in.p2 = [];
end 
   

%% Export data 
s_excel_p = [s_in.p1; s_in.p2];
writetable(struct2table(s_excel_p, 'AsArray',true), filename_p) % export!

fields_del = {'data', 'pressure1','pressure2', 'potential1','potential2', 'pres1_adj','pres2_adj', 'pot1_filtered', 'pot2_filtered', 'p1', 'p2'}; % these fields should not be exported to the excel file
s_excel = rmfield(s_in, fields_del); % remove stated files
writetable(struct2table(s_excel, 'AsArray', true), filename) % export!

end
