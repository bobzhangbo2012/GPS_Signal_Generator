%%========================================================================
% Billy's Analysis
%=========================================================================
% Note that "Data" are in "GPS_Dump" and "reference" is in "ca_code"
sr_mhz = 8;
taus = 1/(sr_mhz * 1e6);
time_i = taus:taus:( length( gps_dump )*taus);
% Tune the gps_dump signal so that we get it down as close to DC as
% possible. Do this with a bulk (guess) and a lock based on squaring the
% bpsk signal to recover the carrier.
freq_shift = 98e3;  % Bulk guess
coarse_tune = gps_dump .* exp(j*time_i'*(2*pi*(freq_shift) ));
tune_tone = abs(fftshift(fft(coarse_tune.^2))); % Square to recover
% Imprecise, but good first guess:
flist = linspace(-sr_mhz/2, sr_mhz/2, length(coarse_tune));
[~,b] = max(tune_tone)
fmax = flist(b)
freq_shift_fine = - fmax/2 * 1e6
fine_tune = coarse_tune .* exp(j*time_i' * (2*pi*(freq_shift_fine)));
fprintf('Used bulk tune of %.2f kHz\n', freq_shift/1e3);
fprintf('Found fine tune offset of %.2f kHz\n', freq_shift_fine / 1e3);
figure
plot(flist, fftshift(20*log10(abs(fft(fine_tune.^2)))))
xlabel('Frequency (MHz)')
ylabel('Power (dB-Arb)')
title('GPS Residual Tone after Squaring and Tuning')
grid on
ax = axis;
axis([-0.01, 0.01, ax(3), ax(4)])
 
% Move on to determine the estimated clock rate for the input data,
% compared to the guess clock rate for the system of 8 MHz. We'll find this
% based on the clock edges of the data, and look at only the 1-bit clocks.
bitChange = abs(diff(angle(fine_tune))) > pi/2;
whereBits = find(bitChange);
bitTime = diff(whereBits);
% Pick the first N spots, then sort them:
firstNBits = bitTime(1:end);
firstNBitsSort = sort(firstNBits);
% Expecting that "one bit" is about 7 or 8 samples between; count relative
% to determine the average. This will only work when 
nCheck = [6,7,8,9];
for nn = 1:length(nCheck)
    nBitsCheck(nn) = sum(firstNBitsSort == nCheck(nn));
end
avgTime = sum(nBitsCheck .* nCheck) / sum(nBitsCheck);
cac_time_guess = sr_mhz / avgTime;
fprintf('Found average of %.2f samples per bit (fast bits only)\n', avgTime)
fprintf('Guessing CACode rate of %.4f MHz, relative to sample rate of %.4f MHz\n', cac_time_guess, sr_mhz)
% Move on to correlating. Generate the CACode and move from here:
sv = 9
ca_code = cacode(sv, sr_mhz / cac_time_guess);
ca_code_col = ca_code(:);
n_repeats = ceil(length(gps_dump) / length(ca_code_col));
ca_code_rep = repmat(ca_code_col, n_repeats, 1);
ca_code_rep = ca_code_rep(1:length(gps_dump));
t_frame = 0.002; % Set the frame time for the FX to 10 ms
n_smp_frame = t_frame * sr_mhz * 1e6
n_frames = floor(length(fine_tune) / n_smp_frame)
% Reshape the matrices:
rec_mat = reshape( fine_tune(1:(n_smp_frame*n_frames)), n_smp_frame, n_frames);
cac_mat = reshape( ca_code_rep(1:(n_smp_frame*n_frames)), n_smp_frame, n_frames);
rec_fft = fft(rec_mat, [], 1);
cac_fft = fft(cac_mat, [], 1);
x_fft = rec_fft .* conj(cac_fft);
x_lag = ifft(x_fft,[],1);
figure
imagesc(abs(x_lag))
xlabel('Arbitrary Frame Number')
ylabel('Correlation Sample Offset')
title('Correlator Output')
 
