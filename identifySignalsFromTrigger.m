function identifySignalsFromTrigger()
    % identifySignalsFromTrigger
    % Author: Zhaoxing Wei, IPCAS, Jan-30-2025
    % 1) Loads "trigger.txt".
    % 2) Analyzes the first two columns (assumed to be heartbeat or respiration).
    % 3) Computes each column’s main frequency.
    % 4) Classifies which column is respiration and which is heartbeat.

    clc; close all; clear;

    %-------------------------------
    % 1. Load the data file
    %-------------------------------
    % Make sure "trigger.txt" is in the same folder as this script,
    % or provide an absolute path (e.g., 'C:/path/to/trigger.txt').
    data = load('trigger.txt');

    [numRows, numCols] = size(data);
    fprintf('Loaded data: %d rows, %d columns.\n', numRows, numCols);

    % If the file has more than two columns, this example only uses the first two.
    colA = data(:, 1);
    colB = data(:, 2);

    %-------------------------------
    % 2. Parameter setup
    %-------------------------------
    % Make sure to adjust Fs to the actual sampling rate.
    % For instance, if the physiological data were recorded at 50 Hz, set Fs = 50.
    Fs = 50;
    N  = length(colA);
    t  = (0:N-1)' / Fs;  % Time axis (seconds)

    %-------------------------------
    % 3. (Optional) Plot the time-domain signals
    %-------------------------------
    figure('Name', 'Raw Waveforms');
    subplot(2, 1, 1);
    plot(t, colA);
    xlabel('Time (s)'); ylabel('Amplitude');
    title('Column 1 Signal');

    subplot(2, 1, 2);
    plot(t, colB);
    xlabel('Time (s)'); ylabel('Amplitude');
    title('Column 2 Signal');

    %-------------------------------
    % 4. Compute power spectrum & find main frequency peaks
    %-------------------------------
    freqA = getMainFreq(colA, Fs);
    freqB = getMainFreq(colB, Fs);

    fprintf('Main frequency of Column 1 = %.3f Hz\n', freqA);
    fprintf('Main frequency of Column 2 = %.3f Hz\n', freqB);

    %-------------------------------
    % 5. Classify signals:
    %    - Heartbeat: typically ~1 Hz (range ~0.8–2 Hz)
    %    - Respiration: typically ~0.1–0.5 Hz
    %    (Simple threshold-based logic for demonstration.)
    %-------------------------------
    labelA = classifySignal(freqA);
    labelB = classifySignal(freqB);

    fprintf('Column 1 appears to be: %s\n', labelA);
    fprintf('Column 2 appears to be: %s\n', labelB);
end

%=======================================================================
% Helper Function 1: Compute the main frequency peak of a signal
%=======================================================================
function mainFreq = getMainFreq(x, Fs)
    x = x - mean(x);  % Remove DC offset
    N = length(x);
    X = fft(x);
    P = abs(X).^2 / N;

    halfN = floor(N/2);
    P = P(1:halfN);
    freqs = (0:halfN-1) * (Fs / N);

    [~, idxMax] = max(P);
    mainFreq = freqs(idxMax);

    % Optional: Plot the power spectrum
    figure('Name','Power Spectrum');
    plot(freqs, P, '-b'); hold on;
    plot(freqs(idxMax), P(idxMax), 'ro');
    xlim([0, 2]);  % Display only 0–2 Hz to highlight respiration vs. heartbeat
    xlabel('Frequency (Hz)');
    ylabel('Power');
    title(sprintf('Main Frequency = %.3f Hz', mainFreq));
    grid on;
end

%=======================================================================
% Helper Function 2: Classify the signal type based on main frequency
%=======================================================================
function label = classifySignal(freqVal)
    % Very simple threshold-based classification:
    % freq < 0.6 Hz => Respiration
    % freq >= 0.6 Hz => Heartbeat
    if freqVal < 0.6
        label = 'Respiration';
    else
        label = 'Heartbeat';
    end
end