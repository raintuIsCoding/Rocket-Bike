clc; clear; close all;

%% === CONFIGURATION ===

% List of thrust curve CSV files (time vs thrust)
curve_files = {
    'data/AeroTech_HP-H135W.csv',
    'data/scuba_thrust_curve.csv',
    % Add more here
};

% Set units for each file (true if input thrust is in lbf)
is_lbf = [true, true];  % Same order as curve_files

% Custom plot labels (optional)
labels = {
    'I115W Motor',
    'Scuba Tank'
};

% Plot styling options
colors = lines(length(curve_files));  % Auto-generate distinct colors

%% === PLOTTING SETUP ===
figure('Color', 'k');
hold on;
ax = gca;
set(ax, ...
    'Color', 'k', ...
    'XColor', 'w', 'YColor', 'w', ...
    'GridColor', 'w', 'GridAlpha', 0.3);
grid on;

title('Thrust Curve Comparison', 'Color', 'w');
xlabel('Time (s)', 'Color', 'w');
ylabel('Thrust (N)', 'Color', 'w');

%% === LOAD AND PLOT EACH CURVE ===
for i = 1:length(curve_files)
    data = readmatrix(curve_files{i});
    t = data(:,1);
    thrust = data(:,2);

    % Convert if in lbf
    if is_lbf(i)
        thrust = thrust / 0.224809;  % Convert to Newtons
    end

    % Use filename as label if none provided
    if length(labels) >= i
        label = labels{i};
    else
        [~, label, ~] = fileparts(curve_files{i});
    end

    plot(t, thrust, 'LineWidth', 2, 'DisplayName', label, 'Color', colors(i,:));
end

legend('TextColor', 'w', 'EdgeColor', 'w', 'Location', 'northeast');
