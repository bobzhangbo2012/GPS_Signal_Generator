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

clc
clear

% Connect to roach times katcp doesn't connect the
%   first time. Therefor this will retry until it does.
roach_connected = 0;
while ~roach_connected
    try
        % Define which firmware to upload
        fw = 'gps_full_signal_2017_May_29_1638.bof'; % .bof file

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
        global_pause = 0.25; % Pause to enforce between writes

    catch
    end
end

% print a empty line for spacing
fprintf('\n');

% Select the SV
sv_1 = 18;
sv_2 = 20;
sv_3 = 22;
sv_4 = 29;

selected_bit_sv1 = SelectSatellite( sv_1 );
selected_bit_sv2 = SelectSatellite( sv_2 );
selected_bit_sv3 = SelectSatellite( sv_3 );
selected_bit_sv4 = SelectSatellite( sv_4 );

% Create Message Data
message_signal = CreateMessageData( [ sv_1 sv_2 sv_3 sv_4 ] );
message_signal_sv1 = message_signal( 1:1250 , : );
message_signal_sv2 = message_signal( 1251:2500 , : );
message_signal_sv3 = message_signal( 2501:3750 , : );
message_signal_sv4 = message_signal( 3751:5000 , : );

message_signal_bytes_1 = ConvertToBytesAndPad( message_signal_sv1 );
repeated_message_signal_bytes_sv1 = message_signal_bytes_1(:);

message_signal_bytes_2 = ConvertToBytesAndPad( message_signal_sv2 );
repeated_message_signal_bytes_sv2 = message_signal_bytes_2(:);

message_signal_bytes_3 = ConvertToBytesAndPad( message_signal_sv3 );
repeated_message_signal_bytes_sv3 = message_signal_bytes_3(:);

message_signal_bytes_4 = ConvertToBytesAndPad( message_signal_sv4 );
repeated_message_signal_bytes_sv4 = message_signal_bytes_4(:);

% Largest number of bytes that the bram can hold is 262144
for count_i = 1:1:51
    repeated_message_signal_bytes_sv1 = [ repeated_message_signal_bytes_sv1 ; message_signal_bytes_1(:) ];
    repeated_message_signal_bytes_sv2 = [ repeated_message_signal_bytes_sv2 ; message_signal_bytes_2(:) ];
    repeated_message_signal_bytes_sv3 = [ repeated_message_signal_bytes_sv3 ; message_signal_bytes_3(:) ];
    repeated_message_signal_bytes_sv4 = [ repeated_message_signal_bytes_sv4 ; message_signal_bytes_4(:) ];
end

% Clean up created file
delete *.alm;

% Write to Selector Bit registers
wordwrite( roach, 'G2_1_SV_SEL_SEL_REG1', selected_bit_sv1(1,1) - 1 );
wordwrite( roach, 'G2_1_SV_SEL_SEL_REG2', selected_bit_sv1(1,2) - 1 );

wordwrite( roach, 'G2_2_SV_SEL_SEL_REG1', selected_bit_sv2(1,1) - 1 );
wordwrite( roach, 'G2_2_SV_SEL_SEL_REG2', selected_bit_sv2(1,2) - 1);

wordwrite( roach, 'G2_3_SV_SEL_SEL_REG1', selected_bit_sv3(1,1) - 1 );
wordwrite( roach, 'G2_3_SV_SEL_SEL_REG2', selected_bit_sv3(1,2) - 1);

wordwrite( roach, 'G2_4_SV_SEL_SEL_REG1', selected_bit_sv4(1,1) - 1 );
wordwrite( roach, 'G2_4_SV_SEL_SEL_REG2', selected_bit_sv4(1,2) - 1 );

% Ensure PRN Signal is turned ON ( Set:  PRN_SHUTDOWN_SWITCH to 0)
%   PRN_SHUTDOWN_SWITCH controls a MUX that selected between a constant
%   zero ( 0 ) or the PRN signal ouput.
% PRN_SHUTDOWN_SWITCH = 0 = PRN is ON
% PRN_SHUTDOWN_SWITCH = 1 = PRN is OFF
wordwrite( roach, 'PRN_SHUTDOWN_SWITCH' , 0);

% MESSAGE_SHUTDOWN_SWITCH = 0 = MESSAGE DATA ON
% MESSAGE_SHUTDOWN_SWITCH = 1 = MESSAGE DATA OFF
wordwrite( roach, 'MESSAGE_SHUTDOWN_SWITCH2', 0);

% MESSAGE_CLK_SELECT = 0 = CLK PRN CLOCK (1.023 MHZ)
% MESSAGE_CLK_SELECT = 1 = MESSAGE CLK (50 bps)
wordwrite( roach, 'MESSAGE_CLK_SELECT', 1);

% Reset GLOBAL_RESET to start transmission
%pause( global_pause ); wordwrite( roach, 'GLOBAL_RESET',0);

wordwrite( roach, 'DAC_dac_reset', 1 );
wordwrite( roach, 'DAC_dac_reset', 0 );

% Write the message signal bits to BRAM
%   Make sure that the message signal are in BYTES before being written
%   to the BRAM.
pause( global_pause );
write(roach, 'Message_Signal1_bram1', repeated_message_signal_bytes_sv1' );

pause( global_pause );
write(roach, 'Message_Signal2_bram1', repeated_message_signal_bytes_sv2' );

pause( global_pause );
write(roach, 'Message_Signal3_bram1', repeated_message_signal_bytes_sv3' );

pause( global_pause );
write(roach, 'Message_Signal4_bram1', repeated_message_signal_bytes_sv4' );
