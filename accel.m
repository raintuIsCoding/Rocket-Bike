function plot_accel()
    % Load data
    data = load('data/dropTest.mat');
    varName = fieldnames(data);
    T = data.(varName{1}); % Dynamically extract the table

    % Time vector in seconds from first timestamp
    t = seconds(T.Timestamp - T.Timestamp(1));

    % Extract components
    ax = T.X;
    ay = T.Y;
    az = T.Z;

    % Optional: magnitude
    amag = sqrt(ax.^2 + ay.^2 + az.^2);

    % Plot
    figure;
    plot(t, ax, 'r', t, ay, 'g', t, az, 'b', t, amag, 'k--', 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Acceleration (m/s^2)');
    title('Acceleration vs Time');
    legend('X', 'Y', 'Z', 'Magnitude');
    grid on;
end