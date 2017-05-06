% ----------------------------------------------------------------------- %
%                       GPS Dump File Analysis                            %
%                                                                         %
%   Description: This file analysis the GNU Radio file .dat file          %
%                                                                         %
%   Created by Kurt Pedrosa and Dr. Billy Barott                          %  
%       Feb 7th 2017   - ERAU Spring 2017                                 %
%                                                                         %
%   Edit --                                                               %      
%                                                                         %
%      + by Kurt Pedrosa - April 2nd 2016:                                %
%           Added new plots, tunned the signal to close to DC, estimated  %
%           clock rate.                                                   %
% ----------------------------------------------------------------------- %

%% Call a GNURadio function to convert complex .dat file to MATLAB matrix.
% Function read_complex_number() needs to be in same directory or
% downloading from http://www.gnuradio.com

[gps_dump_filename, gps_dump_file_path] = uigetfile( '*.dat', 'Select the GNURadio .dat file');
gps_dump = read_complex_binary( strcat( gps_dump_file_path, gps_dump_filename ) );

% First 1/16th of recieved signal
gps_dump = gps_dump(1:end/2);

% Plot Real, Imag and Angle part of the first 1/16th samples of the signal
% figure;
% plot( real( gps_dump ))
% xlabel(' Time (s) ');
% ylabel(' Relative Amplitude (dBm) ' );
% title( ' Real Part of Signal ' );
% 
% figure;
% plot( imag( gps_dump) )
% xlabel(' Time (s) ');
% ylabel(' Relative Amplitude (dBm) ' );
% title( ' Imaginary Part of Signal ' );
% 
% figure;
% plot( angle( gps_dump) )
% xlabel(' Time (s) ');
% ylabel(' Relative Amplitude (dBm) ' );
% title( ' Angle of Signal ' );

%% Analysis

time_t = (1/8e6):(1/8e6):( length( gps_dump )/8e6);

% figure
% subplot( 2,1,1 );
% plot(time_t, angle( gps_dump ) );
% axis([0 1e-3,-4,4]);
% 
% subplot(2,1,2)
% plot(time_t,angle( gps_dump .* exp(j*time_t'*(2*pi*98.75e3))   )); 
% axis([0 1e-3,-4,4]);


% Show the difference in angle over time (Frequency)
angle_diff = diff( angle( gps_dump .* exp(j*time_t'*(2*pi*98.75e3)) ) );


% figure
% plot( angle_diff );
% title( 'Difference in Angle ');
% 
% figure
% plot ( abs(angle_diff) > (pi/2) )
% title(' Difference in Angle with pi/2 threashold ');
% 
% % Find the chip edge in each instance in time_t
% chip_edge = time_t( find( ( abs( angle_diff ) > (pi/2) )));
% 
% figure
% plot( chip_edge );
% title(' Chip Edge in Time ');
% 
% figure
% plot ( diff( chip_edge ) );
% title( 'Change of Chip Edge in Time ' )
% 
% figure
% plot ( sort( diff( chip_edge ) ) )
% title( ' Change of Chip Edge (SORTED) ')

%% Fine tuning
sample_rate_mhz = 8;

time_constant = 1/( sample_rate_mhz * 1e6);

time_i = time_constant:time_constant:( length( gps_dump )*time_constant );

% Tone signal to DC as close as possible.
% This is done by squaring the received signal and recovering the carrier
frequency_shift = 98e3;  % this is a 'bulk guess'

coarse_tune = gps_dump .* exp( j*time_i'*( 2*pi*( frequency_shift ) ));

% Square coarse_tune to recover carrier
tune_tone = abs(fftshift( fft( coarse_tune.^2 )));

% First guess, generate equaly spaced number of points
first_guess = linspace( -sample_rate_mhz/2, sample_rate_mhz/2, ...
    length( coarse_tune ));

% Need clarification from Dr. Barott
[~,b] = max( tune_tone );
fmax = first_guess( b );

% Get a more precise frequency shift
freq_shift_fine = - fmax/2 * 1e6;

fine_tune = coarse_tune .*exp( j*time_i' * ( 2*pi*( freq_shift_fine )));

% Print out what was found
fprintf( ' Bulk tune used was %.3f kHz \n', frequency_shift/1e3 );
fprintf( ' Fine tune offset found was %.3f kHz \n', freq_shift_fine/1e3);

% Plot(s)
figure
plot( first_guess, fftshift( 20*log10( abs( fft( fine_tune.^2 )))));
xlabel( 'Frequency (MHz)' );
ylabel( 'Power (dB Arbitrary)' );
title( 'PRN SV-9 & SV-16 after Squaring and Tuning' );
grid on
ax = axis;
axis([-0.01, 0.01, ax(3), ax(4)])

%% Determine the estimated clock rate for the input data
% Estimated clock rate is compated to the guess clock rate of
% 8 MHz. This is found by looking at the clock edges of the date,
% and look at only the 1-bit clocks.

% Find the bit changes
bit_change = abs( diff( angle( fine_tune ))) > pi/2;

% Location of the bit changes
bit_change_location = find( bit_change );

% Time between each bit change
bit_change_time = diff( bit_change_location );

% Sort the first 'N' spots
first_N_bits = bit_change_time(1:end);
sorted_first_N_bits = sort( first_N_bits );

% It is expected that 'one bit' is about 7 to 8 samples between.
%   Now we will count to determine the average.
nCheck = [6 7 8 9];
for count_n = 1:length( nCheck )
    nBits_check( count_n ) = sum( sorted_first_N_bits == nCheck( count_n ));
end

% Average
average_bit_time = sum( nBits_check .* nCheck ) / sum( nBits_check );

% Guess of the C/A code timing
cacode_timing_guess = sample_rate_mhz / average_bit_time;

% Print out what was found
fprintf( 'Found an average of %.3f samples per bit (fast bits only).\n', ...
    average_bit_time);
fprintf( 'Found a C/A code rate (guess) of %.4f MHz, relative to sample rate of %.4f MHz \n', ...
    cacode_timing_guess, sample_rate_mhz );

%% Correlation and C/A Code generations
sv = 9;

% Create C/A Code
ca_code = cacode( sv, sample_rate_mhz/ cacode_timing_guess);
% ca_code = cacode( sv );
ca_code_column = ca_code(:);

% Repeat C/A Code same amount of times as the data in
number_of_repeats = ceil( length( gps_dump ) / length ( ca_code_column ) );
ca_code_repeat = repmat( ca_code_column, number_of_repeats, 1 );
ca_code_repeat = ca_code_repeat( 1:length( gps_dump ));

% Ask Dr. Barott about setting the frame time for the FX to 10ms
t_frame = 0.002;

number_sample_frames = t_frame * sample_rate_mhz * 1e6;
number_frames = floor( length( fine_tune ) / number_sample_frames );

% Reshape the matraces
fine_tune_mat = ...
    reshape( fine_tune( 1:( number_sample_frames*number_frames )), number_sample_frames, number_frames );
ca_code_mat = ...
    reshape( ca_code_repeat( 1:( number_sample_frames*number_frames )), number_sample_frames, number_frames );

% FFT both matraces
fine_tune_fft = fft( fine_tune_mat, [], 1 );
ca_code_fft = fft( ca_code_mat, [], 1 );
cross_fft = fine_tune_fft .* conj( ca_code_fft );
cross_lag = ifft( cross_fft, [], 1); % Ask Dr. Barott

% Plot
figure
imagesc( abs( cross_lag ));
xlabel( 'Arbitrary Frame Number' );
ylabel( 'Correlation Sample Offset' );
title('Correlator Ouput - SV9 & SV16');

% Plot correlation of one column
figure
plot( abs( cross_lag(:, 1)));
xlabel('Correlation Sample Offset');
ylabel('Correlation Output Value (dB Arbitrary)');
title('First Column of Correlation - SV9 & SV16');
