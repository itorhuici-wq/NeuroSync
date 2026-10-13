clc; clear;

data = load("sub-01_task-motor-imagery_eeg.mat");
all_data = data.eeg.rawdata;

% Revisa el nombre exacto del campo de frecuencia de muestreo
fieldnames(data.eeg)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Ruta a los datos de sujeto 1 (ajusta si mueves las carpetas)
ruta_sub01 = 'C:\Users\Usuario\Desktop\PROYECTO PROCESADO DE SEÑAL\sourcedata\sourcedata\sub-01';
archivo_sub01 = fullfile(ruta_sub01, 'sub-01_task-motor-imagery_eeg.mat');

s1 = load(archivo_sub01);

rawdata = s1.eeg.rawdata;   % [trials x canales x muestras] = [40 x 33 x 4000]
labels  = s1.eeg.label;     % [40 x 1], clase 1 (mano izq.) / clase 2 (mano dcha.)

[n_trials, n_canales, n_muestras] = size(rawdata);
fprintf('Trials: %d | Canales: %d | Muestras por trial: %d\n', n_trials, n_canales, n_muestras);
clases = unique(labels);
for c = clases'
    fprintf('  Clase %d: %d trials\n', c, sum(labels==c));
end

% --- Nombres de los 33 canales ---
% Averiguado en task-motor-imagery_channels.tsv y en code/code/PlotERP.m,
% PlotBEAM.m y channel_location.ced (metadatos y codigo de los autores).
% 1-30: EEG (sistema 10-20 extendido, gorro ZhenTec-10-20-Cap32).
%       El canal 18 (CPz) es la REFERENCIA online (los autores lo ponen a
%       0 en PlotBEAM.m); por eso en el channels.tsv de BIDS solo cuentan
%       29 EEG activos, no 30.
% 31-32: EOG (movimiento ocular): HEOL y HEOR (asi los llama el codigo
%       de los autores; en channels.tsv el segundo aparece como VEOR,
%       misma posicion -> probable inconsistencia de nombre en el dataset).
% 33:   Canal de TRIGGER/marcador de evento, NO es señal EEG. Los autores
%       usan find(MIEEGData(:,33)==2) para localizar el inicio exacto de
%       la imaginacion motora dentro del trial (1=instruccion,
%       2=inicio imaginacion motora, 3=descanso).
chan_labels = {'FP1','FP2','Fz','F3','F4','F7','F8','FCz','FC3','FC4', ...
    'FT7','FT8','Cz','C3','C4','T3','T4','CPz','CP3','CP4', ...
    'TP7','TP8','Pz','P3','P4','T5','T6','Oz','O1','O2', ...
    'HEOL','HEOR','TRIGGER'};
idx_eeg = 1:30;      % canales EEG (incluye CPz=referencia en la pos. 18)
idx_eog = 31:32;     % canales EOG
idx_trigger = 33;    % canal de marcador de evento

% --- Frecuencia de muestreo ---
% El .mat no la guarda, pero esta documentada en task-motor-imagery_eeg.json
% del propio dataset BIDS: SamplingFrequency = 500 Hz.
fs = 500;
t = (0:n_muestras-1) / fs;

%1) Ver un trial, un canal (C3 = canal central, relevante en motor imagery)
trial_id = 1;
canal_id = 14;   % C3
figure('Name', 'Un canal, un trial');
plot(t, squeeze(rawdata(trial_id, canal_id, :)));
xlabel('Tiempo (s)'); ylabel('Amplitud');
title(sprintf('Sub-01 | Trial %d | Canal %s | Clase %d', trial_id, chan_labels{canal_id}, labels(trial_id)));
grid on;

%2) Ver todos los canales EEG de un trial (normalizados y apilados)
figure('Name', 'Todos los canales EEG de un trial');
hold on;
offset_paso = 6; % separacion visual entre canales (en unidades normalizadas)
for k = 1:numel(idx_eeg)
    ch = idx_eeg(k);
    senal_ch = squeeze(rawdata(trial_id, ch, :));
    senal_norm = (senal_ch - mean(senal_ch)) / std(senal_ch); % z-score
    plot(t, senal_norm + k*offset_paso);
end
hold off;
xlabel('Tiempo (s)'); ylabel('Canal (normalizado y desplazado)');
yticks((1:numel(idx_eeg))*offset_paso);
yticklabels(chan_labels(idx_eeg));
title(sprintf('Sub-01 | Trial %d | %d canales EEG', trial_id, numel(idx_eeg)));

%3) Comparar la media de la clase 1 vs la clase 2 en el canal elegido
idx_clase1 = labels == 1;
idx_clase2 = labels == 2;

media_clase1 = squeeze(mean(rawdata(idx_clase1, canal_id, :), 1));
media_clase2 = squeeze(mean(rawdata(idx_clase2, canal_id, :), 1));

figure('Name', 'Media por clase');
plot(t, media_clase1, 'b', 'DisplayName', 'Clase 1 (mano izq.)'); hold on;
plot(t, media_clase2, 'r', 'DisplayName', 'Clase 2 (mano dcha.)');
hold off;
xlabel('Tiempo (s)'); ylabel('Amplitud media');
legend show;
title(sprintf('Sub-01 | Canal %s | Media clase 1 vs clase 2', chan_labels{canal_id}));
grid on;

%4) Espectro (FFT) sencillo de un trial/canal
senal = squeeze(rawdata(trial_id, canal_id, :));
N = length(senal);
Y = fft(senal - mean(senal));
P2 = abs(Y / N);
P1 = P2(1:floor(N/2)+1);
P1(2:end-1) = 2 * P1(2:end-1);
f = fs * (0:floor(N/2)) / N;

figure('Name', 'Espectro de frecuencia');
plot(f, P1);
xlabel('Frecuencia (Hz)'); ylabel('|Amplitud|');
title(sprintf('Sub-01 | Trial %d | Canal %s | FFT', trial_id, chan_labels{canal_id}));
xlim([0 60]); % banda de interes tipica en EEG
grid on;

%5) Heatmap: todos los trials de un canal (tiempo x trial)
figure('Name', 'Heatmap canal x trials');
imagesc(t, 1:n_trials, squeeze(rawdata(:, canal_id, :)));
xlabel('Tiempo (s)'); ylabel('Trial');
title(sprintf('Sub-01 | Canal %s | Todos los trials', chan_labels{canal_id}));
colorbar;
colormap('parula');

%6) Vistazo al canal de TRIGGER (33)  marcadores de evento
figure('Name', 'Canal de trigger (evento)');
plot(t, squeeze(rawdata(trial_id, idx_trigger, :)), 'k', 'LineWidth', 1.2);
xlabel('Tiempo (s)'); ylabel('Codigo de evento');
title(sprintf('Sub-01 | Trial %d | Canal 33 = TRIGGER (1=instr., 2=MI, 3=descanso)', trial_id));
ylim([-0.5 3.5]);
grid on;
