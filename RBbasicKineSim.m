%% HOUSEKEEPING
clc; clear; close all;

%% === SIMULATION INPUT PARAMETERS ===
m = 81.65;                      % Mass (lbs)
v0 = 0;                         % Initial speed (m/s)
v_cruise = 4.47;                % Target cruise speed (10 mph)
t_pedal = 6;                    % Pedal-up time (s)
t_precoast = 9;                 % Coast before motor ignition (s)
t_burn = 3.6;                   % Motor burn time (s)
I_total = 412;                  % Motor impulse (Ns)
t_postcoast = 4;                % Coast after burn (s)
t_brake = 4;                    % Braking time (s)
dt = 0.01;

%% === PHASE 1: Pedal Up ===
t1 = 0:dt:t_pedal;
a1 = v_cruise / t_pedal * ones(size(t1));
v1 = cumtrapz(t1, a1);
x1 = cumtrapz(t1, v1);

%% === PHASE 2: Pre-Burn Coast ===
t2 = 0:dt:t_precoast;
a2 = zeros(size(t2));
v2 = v1(end) * ones(size(t2));
x2 = x1(end) + cumtrapz(t2, v2);

%% === PHASE 3: Motor Burn with Imported Thrust Curve ===
% This section accepts a generic thrust curve CSV file with columns:
% [Time (s), Thrust (lbf or N)] — units must be known/set below.

csv_file = 'data/scuba_thrust_curve.csv';  % Can also be a scuba-generated file
thrust_data = readmatrix(csv_file);    % Generic time vs. thrust input
thrust_time = thrust_data(:,1);        % Time in seconds
thrust_force_raw = thrust_data(:,2);   % Thrust in either lbf or N

% === Set units of input thrust data
input_thrust_in_lbf = true;  % Toggle: set false if already in N

if input_thrust_in_lbf
    thrust_force = thrust_force_raw / 0.224809;  % Convert lbf to N
else
    thrust_force = thrust_force_raw;
end

% === Interpolate thrust to match sim time step
t3 = 0:dt:thrust_time(end);
F_interp = interp1(thrust_time, thrust_force, t3, 'linear', 0);

% === Calculate acceleration, velocity, position during burn
a3 = F_interp / m;
v3 = v2(end) + cumtrapz(t3, a3);
x3 = x2(end) + cumtrapz(t3, v3);

%% === PHASE 4: Post-Burn Coast ===
t4 = 0:dt:t_postcoast;
a4 = zeros(size(t4));
v4 = v3(end) * ones(size(t4));
x4 = x3(end) + cumtrapz(t4, v4);

%% === PHASE 5: Braking ===
t5 = 0:dt:t_brake;
a5 = -v4(1) / t_brake * ones(size(t5));
v5 = v4(1) + cumtrapz(t5, a5);
x5 = x4(end) + cumtrapz(t5, v5);

%% === TIME & POSITION TRACKING ===
t_all = [t1, t1(end)+t2, t1(end)+t2(end)+t3, ...
         t1(end)+t2(end)+t3(end)+t4, ...
         t1(end)+t2(end)+t3(end)+t4(end)+t5];
v_all = [v1, v2, v3, v4, v5];
a_all = [a1, a2, a3, a4, a5];
x_all = [x1, x2, x3, x4, x5];

fprintf("=== Rocket Bike Range Estimation ===\n");
fprintf("Total distance traveled: %.2f meters (%.2f feet)\n", x_all(end), x_all(end)*3.281);
fprintf("FOS 2.0: %.2f meters (%.2f feet)\n", x_all(end)*2, x_all(end)*3.281*2);

%% === REAL DATA IMPORT & PROCESSING ===
data = load('data/carTest3.mat');
accel = data.Acceleration;

% === CONFIGURABLE SETTINGS ===
chosen_axis = 'Y';          % 'X', 'Y', or 'Z'
smoothing_window_sec = 0.5; % For moving average
time_shift = 0.5;           % Manual alignment (sec)
v0_data = 0;                % Initial velocity for real data
bias_offset = 0;          % Constant acceleration bias (m/s^2)

% === Extract raw acceleration data
t_data_raw = seconds(accel.Timestamp - accel.Timestamp(1));
a_data_raw = accel.(chosen_axis);

% === Sampling rate and filter window
fs = 1 / mean(diff(t_data_raw));            % Sampling frequency
window_size = round(smoothing_window_sec * fs);
if mod(window_size,2)==0, window_size = window_size + 1; end

% === Apply offset correction and moving average
a_data_corrected = a_data_raw - bias_offset;
a_data_filt = movmean(a_data_corrected, window_size);

% === Time alignment and integration
t_data_shifted = t_data_raw - time_shift;
v_data = v0_data + cumtrapz(t_data_shifted, a_data_filt);
x_data = cumtrapz(t_data_shifted, v_data);

%% === PLOTS: SIMULATION + MEASURED ===
% === Define phase transition times (in sim time)
phase_times = [ ...
    0, ...                                   % Start of pedal phase
    t1(end), ...                             % End of pedal / start of pre-coast
    t1(end) + t2(end), ...                   % Start of burn
    t1(end) + t2(end) + t3(end), ...         % Start of post-burn coast
    t1(end) + t2(end) + t3(end) + t4(end)];  % Start of braking

phase_labels = {' Pedal', ' Pre-Coast', ' Ignition', ' Post-Coast', ' Braking'};

% === Replot with dashed lines and text labels
figure;

% === Velocity subplot ===
subplot(3,1,1);
plot(t_all, v_all * 2.237, 'b-', 'LineWidth', 2); hold on;
plot(t_data_shifted, v_data * 2.237, 'r--', 'LineWidth', 1.5);
ylabel('Speed (mph)'); title('Velocity vs Time'); grid on;
legend('Simulated','Measured', 'Location','northwest');

% Add phase lines and text
for i = 1:length(phase_times)
    xline(phase_times(i), '--k', 'LineWidth', 1, 'HandleVisibility', 'off');
    y_lim = ylim;
    text(phase_times(i), y_lim(2)*0.95, phase_labels{i}, ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
        'FontSize', 8, 'FontWeight', 'bold', 'HandleVisibility', 'off');
end

% === Acceleration subplot ===
subplot(3,1,2);
plot(t_all, a_all / 9.81, 'b-', 'LineWidth', 2); hold on;
plot(t_data_shifted, a_data_filt / 9.81, 'r--', 'LineWidth', 1.5);
ylabel('Accel (g)'); title('Acceleration vs Time'); grid on;
legend('Simulated','Measured','Location','northwest');

for i = 1:length(phase_times)
    xline(phase_times(i), '--k', 'LineWidth', 1, 'HandleVisibility', 'off');
    y_lim = ylim;
    text(phase_times(i), y_lim(2)*0.95, phase_labels{i}, ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
        'FontSize', 8, 'FontWeight', 'bold', 'HandleVisibility', 'off');
end

% === Position subplot ===
subplot(3,1,3);
plot(t_all, x_all * 3.28084, 'b-', 'LineWidth', 2); hold on;
plot(t_data_shifted, x_data * 3.28084, 'r--', 'LineWidth', 1.5);
ylabel('Distance (ft)'); xlabel('Time (s)');
title('Position vs Time'); grid on;
legend('Simulated','Measured','Location','northwest');

for i = 1:length(phase_times)
    xline(phase_times(i), '--k', 'LineWidth', 1, 'HandleVisibility', 'off');
    y_lim = ylim;
    text(phase_times(i), y_lim(2)*0.95, phase_labels{i}, ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
        'FontSize', 8, 'FontWeight', 'bold', 'HandleVisibility', 'off');
end