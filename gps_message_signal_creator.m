% ----------------------------------------------------------------------- %
%                       GPS Message Signal Creator                        %
%                                                                         %
%   Description: This file creates the message signal and populates the   %
%       appropriate registers in the ROACH.                               %  
%                                                                         %
%   Created by Kurt Pedross                                               %  
%       Jan 12th 2017   - ERAU Spring 2017                                %
% ----------------------------------------------------------------------- %
%addpath('/home/user/Desktop/KurtPedrosa/Pedrosa_kurt_Files/katcp_lib/@katcp/')
addpath('/home/user/Desktop/KurtPedrosa/Pedrosa_kurt_Files/katcp_lib/')

% Definition of constants
gps_week_modulo = 1024;

% Time of Week Creater
%  Description: This section will calculate the GPS time of week and save
%               the value to the BRAM in the ROACH firmware.

% Get current system time
format longG   % Format to get compat fixed decimal

gps_epoch = [1980, 1, 6, 00, 00, 00.000];

% UTC to EST correction. EST is -5 UTC time.
% NOTE that if Daylight Savings Time
%   EST_correction 4 divides by 24  ( 4 hour difference )
EST_correction_DST= 4/24;

% get TRUE gps week
GPS_week = ( ( now + EST_correction_DST ) - datenum(gps_epoch))/7;

% round true gps week down to get current gps weekw
GPS_week_adjusted = floor( GPS_week ); % decimal value for current gps week

% Force GPS_second_of_the_week count to 6 seconds Seconds of week range
% range to 0 - 604,800
disp( datestr( now ) );
GPS_seconds_of_week = ...
floor( (( GPS_week - GPS_week_adjusted )*24*60*60*7)/6)*6;

% 19 LSB of z-count - count of 1.5 ( range 0 - 403,199)
tow_dec = GPS_seconds_of_week/1.5;

% Pad and package the 19 bits for the LSB z-count
tow_bin =  TowPadPackage( tow_dec );

% TODO Comment str2bin_array function
% Splice the 10 MSB of the week number
GPS_week_mod_1024 = ...
    str2bin_array( dec2bin( mod(GPS_week_adjusted, gps_week_modulo ))); % 10 MSB of z-count

% Connect to roach times katcp doesn't connect the 
% %   first time. Therefor this will retry until it does.
roach_connected = 0;
while ~roach_connected
    try
        % Define which firmware to upload
        %fw = 'gps_full_signal_2017_Apr_27_1232.bof'; % .bof file
        %fw = 'gps_full_signal_2017_May_05_1201.bof'; % .bof file
        fw = 'gps_full_signal_2017_May_10_1836.bof'; % .bof file
        
        rhost = '192.168.4.117'; % IP Address for roach being used
        
        fprintf('Attempting to connect to %s and load %s\n', rhost, fw );
        roach = katcp(rhost);
        
        % As per Dr. Barott:
        %   'Don't forget to use the modified KATCP that allows ?poco?
        %   return message. The basic KATCP included in our install 
        %   libraries doesn't do this - have forgotten the small mod
        %   required
        
        progdev( roach, fw );   % Program Roach with defined fw
        
        roach_connected = 1;
        
        % As per Dr. Barott
        global_pause = 0.25; % Pause to enforce between writesSELECTOR_TWO_REG1
        
    catch
    end
end

% Generate Subframe 1
subframe_1 = GenerateSubframe1( GPS_week_mod_1024, tow_bin(1:17), [0 0]);
subframe_2 = GenerateSubframe2( GPS_week_mod_1024, tow_bin(1:17), subframe_1(10, 29:30 ));
subframe_3 = GenerateSubframe3( GPS_week_mod_1024, tow_bin(1:17), subframe_2(10, 29:30 ));

subframe_1_reshaped = ConvertToBytesAndPad( subframe_1 );
subframe_2_reshaped = ConvertToBytesAndPad( subframe_2 );
subframe_3_reshaped = ConvertToBytesAndPad( subframe_3 );


message_signal = [ subframe_1_reshaped, subframe_2_reshaped, subframe_3_reshaped ];

% % testing bram
% test_message = zeros(10,30);
% for count_j = 1:10
%     for count_k = 1:2:30
%         test_message( count_j, count_k ) = 1;
%     end
% end
% 
% test_message_bytes = ConvertToBytesAndPad(test_message);



repeating_array = message_signal(:);

for count_i = 1:1:1023
    repeating_array = [ repeating_array; message_signal(:) ];
end

% Select the SV
selected_bits = SelectSatellite(10);

% Write to Selector Bit registers
wordwrite( roach, 'G2_SV_Selector_SELECTOR_ONE_REG', selected_bits(1,1) );
wordwrite( roach, 'G2_SV_Selector_SELECTOR_TWO_REG', selected_bits(1,2) );

% Ensure PRN Signal is turned ON ( Set:  PRN_SHUTDOWN_SWITCH to 0)
%   PRN_SHUTDOWN_SWITCH controls a MUX that selected between a constant
%   zero ( 0 ) or the PRN signal ouput.
pause( global_pause ); wordwrite( roach, 'PRN_SHUTDOWN_SWITCH' ,0 );

pause( global_pause ); wordwrite( roach, 'MESSAGE_CLK_SELECT', 1 );


pause( global_pause ); wordwrite( roach, 'MESSAGE_SHUTDOWN_REG', 0 );
% Reset GLOBAL_RESET to start transmission
%pause( global_pause ); wordwrite( roach, 'GLOBAL_RESET',0);

pause( global_pause ); wordwrite( roach, 'DAC_dac_reset', 1 );
pause( global_pause ); wordwrite( roach, 'DAC_dac_reset', 0 );

% Write the message signal bits to BRAM
%   Make sure that the message signal are in BYTES before being written
%   to the BRAM.
pause( global_pause ); 
write(roach, 'Message_Signal_bram1', repeating_array' )

