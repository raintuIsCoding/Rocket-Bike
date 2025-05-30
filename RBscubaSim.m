%% HOUSEKEEPING + EXPORT
clc; clear; close all;

export_thrust_curve_csv = true;  % Set to false to skip export

%% === CONFIGURABLE PARAMETERS ===

% === Adjustable Variables ===
P0 = 1350 * 6894.76;            % Initial tank pressure (psi -> Pa)
d_nozzle = (1/4) * 0.0254;      % Nozzle diameter (1/2 in -> m)

% === Measurements & Geometry ===
V_tank = 10 * 1e-3;             % Tank volume (liters -> m^3)
A_nozzle = pi * (d_nozzle/2)^2; % Nozzle area (m^2)
mass_total = 81.65;             % Mass of rider + vehicle (kg)

% === Environmental Constants ===
T0 = 293;                       % Initial temperature (K)
R = 287;                        % Specific gas constant for air (J/kg·K)
gamma = 1.4;                    % Heat capacity ratio for air
P_atm = 83400;                  % Atmospheric pressure (Pa)

% === Simulation Time Settings ===
dt = 0.01;                      % Time step (s)
t_max = 10;                     % Total simulation time (s)

%% === INITIAL CONDITIONS ===
rho0 = P0 / (R * T0);  % Initial air density (kg/m^3)
m_air = rho0 * V_tank; % Initial air mass (kg)
P = P0;                % Tank pressure (Pa)
T = T0;                % Tank temperature (K)

%% === TIME INTEGRATION SETUP ===
time = 0:dt:t_max;
F_thrust = zeros(size(time));
P_tank = zeros(size(time));
m_dot_log = zeros(size(time));
m_air_log = zeros(size(time));

for i = 1:length(time)
    if P <= P_atm
        break;  % Stop thrust when pressure equalizes
    end

    % === Determine if flow is choked
    critical_P = P * (2 / (gamma + 1))^(gamma / (gamma - 1));

    if ~exist('choke_break_index', 'var') && critical_P <= P_atm
        choke_break_index = i;  % Mark the moment choked flow ends
    end

    if critical_P > P_atm  % Choked flow
        m_dot = A_nozzle * P * sqrt(gamma / (R * T) * ...
                 (2 / (gamma + 1))^((gamma + 1)/(gamma - 1)));
        v_exit = sqrt(gamma * R * T);  % Choked exit velocity
    else  % Non-choked flow
        P_ratio = P_atm / P;
        m_dot = A_nozzle * P * sqrt((2 * gamma) / (R * T * (gamma - 1)) * ...
               (P_ratio^(2/gamma) - P_ratio^((gamma + 1)/gamma)));
        v_exit = sqrt(2 * R * T * (1 - (P_atm / P)^((gamma - 1)/gamma)));
    end

    thrust = m_dot * v_exit;
    F_thrust(i) = thrust;
    m_dot_log(i) = m_dot;
    m_air_log(i) = m_air;
    P_tank(i) = P;

    % Update tank conditions
    m_air = m_air - m_dot * dt;
    P = (m_air / V_tank) * R * T;  % Ideal gas law
end

%% === TRIM OUTPUT TO ACTUAL SIM TIME ===
valid_idx = find(F_thrust > 0);
time = time(valid_idx);
F_thrust = F_thrust(valid_idx);
m_dot_log = m_dot_log(valid_idx);
P_tank = P_tank(valid_idx);

%% === ACCELERATION & VELOCITY INTEGRATION ===
a = F_thrust / mass_total;
v = 4.47 + cumtrapz(time, a);        % Start at 10 mph
x = cumtrapz(time, v);               % Integrate that to get distance

if exist('choke_break_index', 'var')
    choke_break_time = time(choke_break_index);
else
    choke_break_time = NaN;  % In case flow stayed choked
end

% Convert to English units
F_thrust_lbf = F_thrust * 0.224809;
a_g = a / 9.81;
v_mph = v * 2.237;
x_ft = x * 3.28084;

%% === PERFORMANCE METRICS (Command Window Output) ===

% Total impulse (N·s)
total_impulse = trapz(time, F_thrust);

% Peak thrust (N and lbf)
peak_thrust = max(F_thrust);
peak_thrust_lbf = peak_thrust * 0.224809;

% Peak acceleration (g)
peak_accel_g = max(a_g);

% Δv (m/s and mph)
delta_v = v(end) - v(1);       % m/s
delta_v_mph = delta_v * 2.237; % mph

% Total distance traveled (m and ft)
total_distance_m = x(end);
total_distance_ft = total_distance_m * 3.28084;

% Burn duration
burn_duration = time(end);  % Time at which thrust effectively ends

% Burn duration while flow is choked
if exist('choke_break_index', 'var')
    burn_choked = time(choke_break_index);  % Time at which choked flow ends
else
    burn_choked = time(end);  % Flow remained choked entire burn
end

% === Display Results ===
fprintf('\n=== PERFORMANCE SUMMARY ===\n');
fprintf('Total Impulse:          %.2f N·s\n', total_impulse);
fprintf('Peak Thrust:            %.2f N (%.2f lbf)\n', peak_thrust, peak_thrust_lbf);
fprintf('Peak Acceleration:      %.2f g\n', peak_accel_g);
fprintf('Delta-V:                %.2f m/s (%.2f mph)\n', delta_v, delta_v_mph);
fprintf('Total Distance:         %.2f m (%.2f ft)\n', total_distance_m, total_distance_ft);
fprintf('Burn Duration:          %.2f s\n', burn_duration);
fprintf('Burn Duration (Choked): %.2f s\n', burn_choked);
fprintf('=============================\n\n');

%% === OPTIONAL: Export CSV Thrust Curve ===
if export_thrust_curve_csv
    thrust_data = [time(:), F_thrust_lbf(:)];  % Time in seconds, Thrust in lbf
    header = {'Time_s', 'Thrust_lbf'};
    csv_filename = fullfile('data', 'scuba_thrust_curve.csv');  % adjust path as needed

    % Ensure folder exists
    if ~exist('data', 'dir')
        mkdir('data');
    end

    % Write CSV with header
    fid = fopen(csv_filename, 'w');
    fprintf(fid, '%s,%s\n', header{:});
    fclose(fid);
    dlmwrite(csv_filename, thrust_data, '-append');
    fprintf('CSV thrust curve written to: %s\n', csv_filename);
end

%% === PLOTS ===
figure;

set(gca, 'Color', 'k');  % Whole figure background

% === Thrust ===
subplot(4,1,1);
plot(time, F_thrust_lbf, 'LineWidth', 2); grid on;
ylabel('Thrust (lbf)'); title('Thrust vs Time');
if ~isnan(choke_break_time)
    xline(choke_break_time, '--k', 'LineWidth', 1);
end

% === Acceleration ===
subplot(4,1,2);
plot(time, a_g, 'LineWidth', 2); grid on;
ylabel('Accel (g)'); title('Acceleration vs Time');
if ~isnan(choke_break_time)
    xline(choke_break_time, '--k', 'LineWidth', 1);
end

% === Velocity ===
subplot(4,1,3);
plot(time, v_mph, 'LineWidth', 2); grid on;
ylabel('Velocity (mph)'); title('Velocity vs Time');
if ~isnan(choke_break_time)
    xline(choke_break_time, '--k', 'LineWidth', 1);
end

% === Position ===
subplot(4,1,4);
plot(time, x_ft, 'LineWidth', 2); grid on;
ylabel('Position (ft)'); xlabel('Time (s)');
title('Position vs Time');
if ~isnan(choke_break_time)
    xline(choke_break_time, '--k', 'LineWidth', 1);
end

text(choke_break_time, ylim(gca)*[0;1]*0.95, 'Choked Flow Ends', ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
    'FontSize', 8, 'FontWeight', 'bold');