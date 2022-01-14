% Gabriella Colletti
% Project 1 Part B

%====================================================================%
clear;close all

% Importing Flight Log CSV 
data = readtable('output.csv', VariableNamingRule='preserve');
column_names = data.Properties.VariableNames;

% Number of Columns and Row
[rows, cols] = size(data);
fprintf('Number of Rows: %d\n', rows);
fprintf('Number of Columns: %d\n', cols);

% Data Before NAN Value Imputation
fprintf('Data Before Imputing Null Values\n')
display(data(1:5,:));

% Impute NAN values
addpath('/MATLAB Drive/')
matrix = table2array(data);
new_matrix = inpaint_nans(matrix, 1);
data = array2table(new_matrix,  VariableNames= column_names);

% Data After NAN Value Imputation
fprintf('Data After Imputing Null Values But Before Normalizing\n')
display(data(1:5,:));

% Normalize Feature Ranges between 0 and 1
matrix = table2array(data);
new_matrix = normalize(matrix, 'range');
data = array2table(new_matrix,  VariableNames= column_names);

% Data After Normalization
fprintf('Data After Normalization\n')
display(data(1:5,:));

% Verify Constant Timestamp 
timestamp_column = data(:, 'timestamp');
timestamp_vector = table2array(timestamp_column);
plot_delta(timestamp_vector);



%---------- PLOT TIMESTAMP DELTA ----------------------------%
function timestamp = plot_delta(timestamp)
%timestamp is the 1D vector of timestamps
deltas = [];
for i=300:size(timestamp)-1
    deltas = [deltas  timestamp(i+1) - timestamp(i)];
end 
figure
x = 300:size(timestamp)-1;
plot(x,deltas)
xlabel('Timestamp Index')
ylabel('Delta Timestamp')
title('Comparison of Timestamp Deltas')
end





