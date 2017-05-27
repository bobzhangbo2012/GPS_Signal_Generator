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
        fw = 'gps_full_signal_2017_May_22_1841.bof'; % .bof file

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

% Create Message Data
message_signal = CreateMessageData();

message_signal_bytes = ConvertToBytesAndPad( message_signal );
repeating_array = message_signal_bytes(:);

% Largest number of bytes that the bram can hold is 262144
for count_i = 1:1:727
    repeating_array = [ repeating_array; message_signal_bytes(:) ];
end

% Select the SV
selected_bit_sv1 = SelectSatellite(2);
selected_bit_sv2 = SelectSatellite(4);
selected_bit_sv3 = SelectSatellite(6);
selected_bit_sv4 = SelectSatellite(9);
% Write to Selector Bit registers
wordwrite( roach, 'G2_1_SV_SEL_SEL_REG1', selected_bit_sv1(1,1) );
wordwrite( roach, 'G2_1_SV_SEL_SEL_REG2', selected_bit_sv1(1,2) );

wordwrite( roach, 'G2_2_SV_SEL_SEL_REG1', selected_bit_sv2(1,1) );
wordwrite( roach, 'G2_2_SV_SEL_SEL_REG2', selected_bit_sv2(1,2) );

wordwrite( roach, 'G2_3_SV_SEL_SEL_REG1', selected_bit_sv3(1,1) );
wordwrite( roach, 'G2_3_SV_SEL_SEL_REG2', selected_bit_sv3(1,2) );

wordwrite( roach, 'G2_4_SV_SEL_SEL_REG1', selected_bit_sv4(1,1) );
wordwrite( roach, 'G2_4_SV_SEL_SEL_REG2', selected_bit_sv4(1,2) );

% Ensure PRN Signal is turned ON ( Set:  PRN_SHUTDOWN_SWITCH to 0)
%   PRN_SHUTDOWN_SWITCH controls a MUX that selected between a constant
%   zero ( 0 ) or the PRN signal ouput.
% PRN_SHUTDOWN_SWITCH = 0 = PRN is ON
% PRN_SHUTDOWN_SWITCH = 1 = PRN is OFF
pause( global_pause ); wordwrite( roach, 'PRN_SHUTDOWN_SWITCH' , 1);

% MESSAGE_SHUTDOWN_SWITCH = 0 = MESSAGE DATA ON
% MESSAGE_SHUTDOWN_SWITCH = 1 = MESSAGE DATA OFF
pause( global_pause ); wordwrite( roach, 'MESSAGE_SHUTDOWN_SWITCH2', 1);

% MESSAGE_CLK_SELECT = 0 = CLK PRN CLOCK (1.023 MHZ)
% MESSAGE_CLK_SELECT = 1 = MESSAGE CLK (50 bps)
pause( global_pause ); wordwrite( roach, 'MESSAGE_CLK_SELECT', 1);

% Reset GLOBAL_RESET to start transmission
%pause( global_pause ); wordwrite( roach, 'GLOBAL_RESET',0);

pause( global_pause ); wordwrite( roach, 'DAC_dac_reset', 1 );
pause( global_pause ); wordwrite( roach, 'DAC_dac_reset', 0 );

% Write the message signal bits to BRAM
%   Make sure that the message signal are in BYTES before being written
%   to the BRAM.
pause( global_pause );
write(roach, 'Message_Signal1_bram1', repeating_array' );

pause( global_pause );
write(roach, 'Message_Signal2_bram1', repeating_array' );

pause( global_pause );
write(roach, 'Message_Signal3_bram1', repeating_array' );

pause( global_pause );
write(roach, 'Message_Signal4_bram1', repeating_array' );
