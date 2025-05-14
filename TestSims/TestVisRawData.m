clc; clear; close all;

%% === SIMULATED PARAMETERS ===
m = 81.65;                 % Mass (kg)
I_total = 720;             % Impulse (Ns)
burn_time = 2.8;           % Burn time (s)
v0 = 4.47;                 % Initial speed (m/s)
dt = 0.01;

% Simulated time and acceleration
t_sim = 0:dt:burn_time;
a_sim = (I_total / burn_time) / m * ones(size(t_sim));
v_sim = v0 + cumtrapz(t_sim, a_sim);

%% === IMPORT MEASURED ACCELERATION DATA ===
data = load('data/carTest.mat');
% Extract the acceleration table
accel = data.Acceleration;

% Convert Timestamp to seconds from start
t_data_raw = seconds(accel.Timestamp - accel.Timestamp(1));

% Choose axis based on orientation
a_data_raw = accel.Y;  % or accel.Y or accel.Z

%% === PARAMETERS TO TWEAK ===
lowpass_cutoff_Hz = 2.0;      % Adjust for smoothing aggressiveness
time_shift = 0.5;             % Shift in seconds (positive = delay, negative = advance)

%% === LOW-PASS FILTERING ===
fs = 1 / mean(diff(t_data_raw));       % Sample rate from time vector
% Moving average window (in seconds)
smoothing_window_sec = 0.5;  % Adjust for more or less smoothing
window_size = round(smoothing_window_sec * fs);

% Ensure window size is odd for centered filter
if mod(window_size,2) == 0
    window_size = window_size + 1;
end

% Apply moving average
a_data_filt = movmean(a_data_raw, window_size);

%% === TIME SHIFT ===
t_data_shifted = t_data_raw - time_shift;

%% === VELOCITY INTEGRATION ===
v_data = v0 + cumtrapz(t_data_shifted, a_data_filt);

%% === PLOT VELOCITY COMPARISON ===
figure;
plot(t_sim, v_sim * 2.237, 'b-', 'LineWidth', 2); hold on;
plot(t_data_shifted, v_data * 2.237, 'r--', 'LineWidth', 2);
legend('Simulated Velocity','Measured Velocity');
xlabel('Time (s)'); ylabel('Velocity (mph)');
title('Simulated vs Measured Velocity Curve');
grid on;

%% === OPTIONAL: Plot Raw vs Filtered Accel ===
figure;
plot(t_data_raw, a_data_raw, 'k:', 'DisplayName', 'Raw'); hold on;
plot(t_data_raw, a_data_filt, 'r-', 'DisplayName', 'Filtered');
xlabel('Time (s)'); ylabel('Accel (m/s^2)');
title('Measured Acceleration: Raw vs Filtered');
legend; grid on;
