% Gabriella Colletti
% Project 1 Part B

%====================================================================%
clear;close all

%------------------------- STEP 1 ------------------------------_%
data = get_data('noid.csv');               % Get Normalized Data
noid_data = data(6000:19000, :);           % Chop off turbulent data
%------------------------- STEP 2 ------------------------------_%
% Calculate a_lsm from servo_respone = a_lsm* roll_error using LSM
[A_lsm, roll_error, servo_output] = calculate_Alsm(noid_data);
%------------------------- STEP 3 ------------------------------_%
data = get_data('changed_flight.csv');    % Get Normalized Data
changed_data = data(2000:12000, :);           % Chop off turbulent data
%------------------------- STEP 4 ---- --------------------------_%
% Calculate a_lsm from servo_respone = a_lsm* roll_error using LSM
[A_lsm_changed, roll_error_changed, servo_changed] = calculate_Alsm(changed_data);
%------------------------- STEP 5 ------------------------------_%
fprintf('Our a_lsm values are %.4f and %.4f\n', A_lsm, A_lsm_changed);
%------------------------- STEP 6 ------------------------------_%
beta = 0.9999998;                                          % Noid tuned beta
a_rlsm = get_rlsm(roll_error,servo_output, beta, "Noid Data");   % Noid a_rlsm
beta =1;                                                   % Changed Flight tuned beta
a_rlsm_changed = get_rlsm(roll_error_changed,servo_changed,beta, "Changed Data");   % Changed a_rlsm
%------------------------- STEP 7 ------------------------------_%
data = get_data('norm2change2norm.csv');   % Get Normalized Data
[A_lsm_3, roll_error_3, servo_output_3] = calculate_Alsm(data);
%------------------------- STEP 8 ------------------------------_%
% See function detect()
%------------------------- STEP 9 ------------------------------_%
beta = 1;
detect(roll_error_3,servo_output_3, beta);

 %================== FUNCTIONS =======================% 

%------------------------GET A_LSM --------------------------%
function [A_lsm, roll_error, servo_output] = calculate_Alsm(data)
    % Calculate Roll Error
    nav_output = table2array(data(:, "NAV_CONTROLLER_OUTPUT.nav_roll"));
    attitude = table2array(data(:, "ATTITUDE.roll"));  % Convert radians to degrees
    roll_error = nav_output - attitude;                % ROLL ERROR = NAV_OUTPUT - ATTITUDE
   
    % Uncomment to see plot of nav_output and attitude
    %figure 
    %plot(1:size(attitude,1),attitude,1:size(attitude,1),nav_output )
    %legend('attitude', 'nav_output')

    % Verify Constant Timestamp 
    %Timestamp is constant enough to do RLSM
    %timestamp_column = data(:, 'timestamp');
    %timestamp_vector = table2array(timestamp_column);
    %plot_delta(timestamp_vector);

    % Servo_response = A*roll_error
    servo_output = table2array(data(:,"SERVO_OUTPUT_RAW.servo1_raw"));
    
    % Calculate A = (X^T *X)^-1 * X^T * Y 
    % where X=roll_error and Y = servo_response
    x_t =transpose(roll_error);
    A_lsm = inv(x_t*roll_error)*x_t*servo_output;

end 

%-----------------------GET A_RLSM --------------------------%
function a_rlsm = get_rlsm(X,Y, Beta, string)
% X= roll error, Y =servo_output, Beta = Forgetting Factor
N = length(X);  % Number of Datapoints
P=[0.5];        % Amount of Overshoot: How quickly it will settle
C = [0];        % Parameter Drift
a_rlsm = [0,0];    % A_rlsm
P=[0.5]*eye(1);    % Overshoot: How quickly it will settle

% === CALCULATE C USING RLSM procedure and X, Y ===+% 
for i = 1:N
    Kalman = (P*X(i)')/(1 + X(i)*P*X(i)');
    C = C + Kalman*(Y(i) - X(i)*C );
    P = ( eye(1) - Kalman*X(i) )*P/Beta;
    % save values for plotting later
    a_rlsm = [a_rlsm C(1)];
end

% Plot the learned value against the LSM value
figure 
hold on
k = 1:N;
plot(k, a_rlsm(3:N+2))
xlabel('Iteration (k)')
ylabel('Value of A')
title('Learned A values using RLSM for '+string)
legend("RLSM A (Beta: "+ Beta +")")
end    

%-----------------------DETECT BEHAVIOR --------------------------%
function detect(X,Y, Beta)
% X= roll error, Y =servo_output, Beta = Forgetting Factor
Y=Y';
N = size(X, 1); % Number of Datapoints
k = 1:N;        % Number of Iterations
P=[0.5];        % Amount of Overshoot: How quickly it will settle
C = [0];        % Parameter Drift
is_normal = 1;  % Normalcy boolean
a_rlsm = [];    % A_rlsm
% === CALCULATE C USING RLSM procedure and X, Y ===+% 
for i = 1:N
    Kalman = ( P*X(i)' )/( 1 + X(i)*P*X(i)' );
    C = C + Kalman*( Y(i) - X(i)*C );
    P = ( eye(1) - Kalman*X(i) )*P/Beta;
    % save values for plotting later
    a_rlsm= [a_rlsm C(1)];

    % DETECTION - Using Slope as an indicator of malicious impact
    window_size = 1400;    % Number of previous r_lsm values to look at
    if i > window_size
        if (a_rlsm(i)-a_rlsm(i-window_size)<0) && (is_normal==1)
            fprintf("Behavior has become anomalous at k= %.2f\n", i/10000);
            is_normal = 0;
        elseif(a_rlsm(i)-a_rlsm(i-window_size)>0) && (is_normal == 0)
            fprintf("Behavior has returned to normalcy at k= %.2f\n", (i-window_size)/10000);
            is_normal = 1;
        end
    end
end
 % Plot the learned value against the LSM value
figure 
hold on
plot(k, a_rlsm);
xlabel('Iteration (k)')
ylabel('Value of A')
title('Detecting if A values are outside Normalcy Profile')
legend("RLSM A (Beta: "+ Beta +")")
end       

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


%---------- IMPORT AND CLEAN DATA----------------------------%
function data = get_data(path)
    % Importing Flight Log CSV 
    data = readtable(path, VariableNamingRule='preserve');
    column_names = data.Properties.VariableNames;
    
    % Uncomment to see Data Before NAN Value Imputation
    %fprintf('Data Before Imputing Null Values\n')
    %display(data(1:5,:));
    
    % Impute NAN values
    addpath('/MATLAB Drive/')
    matrix = table2array(data);
    new_matrix = inpaint_nans(matrix, 1);
    data = array2table(new_matrix,  VariableNames= column_names);
    
    % Uncomment to see Data After NAN Value Imputation
    %fprintf('Data After Imputing Null Values But Before Normalizing\n')
    %display(data(1:5,:));
    
    % Convert radians to degrees
    data(:, "ATTITUDE.roll")= array2table(rad2deg(table2array(data(:, "ATTITUDE.roll"))));
    
    % Normalize Feature Ranges between 0 and 1
    matrix = table2array(data);
    new_matrix = normalize(matrix, 'range');
    data = array2table(new_matrix,  VariableNames= column_names);
    
    % Uncomment to see Data After Normalization
    %fprintf('Data After Normalization\n')
    %display(data(1:5,:));
    
 
end

