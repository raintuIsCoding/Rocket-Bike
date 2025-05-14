clc; clear; close all;

%% === PARAMETERS ===
m = 81.65;                 % Total mass (kg)
v0 = 4.47;                 % Initial speed (m/s)
dt = 0.01;                 % Time step

%% === INPUT MOTOR DATA ===
% Format: {'Name', Impulse (Ns), Burn Time (s)}
motors = {
    'I200W', 330, 1.5;
    'I600R', 640, 1.2;
    'J500G', 723, 1.4;
    'J350W', 700, 2.1;
    'J420R', 670, 1.5;
    'I300T', 440, 1.4;
    'I1299N-P', 430, 0.33;
    'I435T', 600, 1.3;
    'I211W', 420, 2.3;
    'I357T', 340, 1.0;
    'I59WN-P', 486, 7.5;
    'I161W', 320, 2.2;
    'I218R', 330, 1.5;
    'I285R', 420, 1.5;
    'I180W', 326, 1.8;
    'I245G', 351, 1.4;
    'I327DM', 546, 1.7;
    'I366R', 550, 1.6;
    'I229T', 407, 1.8;
    'I115W', 412, 3.6;
    'I121R', 399, 1.9;
    '1599N', 410, 0.7;
    'I170G', 419, 2.5;
};

%% === INIT STORAGE ===
results = [];  % For table
I_time = {};
J_time = {};

%% === SIMULATION LOOP ===
for i = 1:size(motors,1)
    name = motors{i,1};
    I_total = motors{i,2};
    burn = motors{i,3};
    
    F_avg = I_total / burn;
    a_avg = F_avg / m;
    G_avg = a_avg / 9.81;
    delta_v = I_total / m;
    v_final = v0 + delta_v;

    % Time vector & velocity profile
    t = 0:dt:burn;
    a = F_avg / m * ones(size(t));
    v = v0 + cumtrapz(t, a);

    % Store by class
    motor_class = name(1);
    if motor_class == 'I'
        I_time{end+1} = struct('name',name,'t',t,'v',v,'a',a);
    else
        J_time{end+1} = struct('name',name,'t',t,'v',v,'a',a);
    end

    % Store for summary table
    results = [results; {name, I_total, burn, F_avg, a_avg, G_avg, delta_v*2.237, v_final*2.237}];
end

%% === SUMMARY TABLE ===
T = cell2table(results, ...
    'VariableNames', {'Motor','Impulse_Ns','Burn_s','Thrust_N','Accel_mps2','Gforce','DeltaV_mph','FinalSpeed_mph'});

% Format table data for display: round and convert numeric to string
formattedData = cell(size(T));
formattedData(:,1) = T.Motor;  % Keep motor names as-is

for col = 2:width(T)
    for row = 1:height(T)
        formattedData{row, col} = sprintf('%.2f', T{row, col});
    end
end

% Display in UI table
f = figure('Name','Motor Performance Summary','NumberTitle','off','Position',[100 100 1000 400]);
uitable(f, 'Data', formattedData, ...
           'ColumnName', T.Properties.VariableNames, ...
           'Units','normalized', ...
           'Position',[0 0 1 1]);

%% === PLOTS ===
figure;
subplot(2,1,1); hold on;
for i = 1:length(I_time)
    plot(I_time{i}.t, I_time{i}.v * 2.237, 'DisplayName', I_time{i}.name);
end
title('I-Class Motors: Velocity vs Time'); ylabel('Speed (mph)'); grid on; legend;

subplot(2,1,2); hold on;
for i = 1:length(J_time)
    plot(J_time{i}.t, J_time{i}.v * 2.237, 'DisplayName', J_time{i}.name);
end
title('J-Class Motors: Velocity vs Time'); ylabel('Speed (mph)'); xlabel('Time (s)'); grid on; legend;

%% === ACCELERATION PLOTS ===
figure;
subplot(2,1,1); hold on;
for i = 1:length(I_time)
    plot(I_time{i}.t, I_time{i}.a, 'DisplayName', I_time{i}.name);
end
title('I-Class Motors: Acceleration vs Time'); ylabel('Accel (m/s^2)'); grid on; legend;

subplot(2,1,2); hold on;
for i = 1:length(J_time)
    plot(J_time{i}.t, J_time{i}.a, 'DisplayName', J_time{i}.name);
end
title('J-Class Motors: Acceleration vs Time'); ylabel('Accel (m/s^2)'); xlabel('Time (s)'); grid on; legend;
