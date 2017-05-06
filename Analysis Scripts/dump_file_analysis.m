% ----------------------------------------------------------------------- %
%                       GPS Dump File Analysis                            %
%                                                                         %
%   Description: This file analysis the GNU Radio file .dat file          %
%                                                                         %
%   Created by Kurt Pedrosa and Dr. Billy Barott                          %  
%       Feb 7th 2017   - ERAU Spring 2017                                %      
% ----------------------------------------------------------------------- %

%% Call a GNURadio function to convert complex .dat file to MATLAB matrix.
% Function read_complex_number() needs to be in same directory or
% downloading from http://www.gnuradio.com

gps_dump_filename = uigetfile( '*.dat', 'Select the GNURadio .dat file');
gps_dump = read_complex_binary( gps_dump_filename );

% First 1/16th of recieved signal
gps_dump_chopped = gps_dump(1:end/16);
%% Plot the first 1/16th of the Signal
% Plot Real, Imag and Angle part of the first 1/16th samples of the signal
figure;
plot( real( gps_dump_chopped ))
xlabel(' Time (s) ');
ylabel(' Relative Amplitude (dBm) ' );
title( ' Real Part of Signal ' );

figure;
plot( imag( gps_dump_chopped) )
xlabel(' Time (s) ');
ylabel(' Relative Amplitude (dBm) ' );
title( ' Imaginary Part of Signal ' );

figure;
plot( angle( gps_dump_chopped) )
xlabel(' Time (s) ');
ylabel(' Relative Amplitude (dBm) ' );
title( ' Angle of Signal ' );

%% Analysis

time_t = (1/8e6):(1/8e6):( length( gps_dump_chopped )/8e6);

figure
subplot( 2,1,1 );
plot(time_t, angle( gps_dump_chopped ) );
axis([0 1e-3,-4,4]);

subplot(2,1,2)
plot(time_t,angle( gps_dump_chopped .* exp(j*time_t'*(2*pi*98.75e3))   )); 
axis([0 1e-3,-4,4]);


% Show the difference in angle over time (Frequency)
angle_diff = diff( angle( gps_dump_chopped .* exp(j*time_t'*(2*pi*98.75e3)) ) );


figure
plot( angle_diff );
title( 'Difference in Angle ');

figure
plot ( abs(angle_diff) > (pi/2) )
title(' Difference in Angle with pi/2 threashold ');

% Find the chip edge in each instance in time_t
chip_edge = time_t( find( ( abs( angle_diff ) > (pi/2) )));

figure
plot( chip_edge );
title(' Chip Edge in Time ');

figure
plot ( diff( chip_edge ) );
title( 'Change of Chip Edge in Time ' )

figure
plot ( sort( diff( chip_edge ) ) )
title( ' Change of Chip Edge (SORTED) ')