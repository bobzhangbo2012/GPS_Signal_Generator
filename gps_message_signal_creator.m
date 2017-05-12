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

% Connect to roach times katcp doesn't connect the
%   first time. Therefor this will retry until it does.
% roach_connected = 0;
% while ~roach_connected
%     try
%         % Define which firmware to upload
%         %fw = 'gps_full_signal_2017_Apr_27_1232.bof'; % .bof file
%         %fw = 'gps_full_signal_2017_May_05_1201.bof'; % .bof file
%         fw = 'gps_full_signal_2017_May_10_1836.bof'; % .bof file
%
%         rhost = '192.168.4.117'; % IP Address for roach being used
%
%         fprintf('Attempting to connect to %s and load %s\n', rhost, fw );
%         roach = katcp(rhost);
%
%         % As per Dr. Barott:
%         %   'Don't forget to use the modified KATCP that allows ?poco?
%         %   return message. The basic KATCP included in our install
%         %   libraries doesn't do this - have forgotten the small mod
%         %   required
%
%         progdev( roach, fw );   % Program Roach with defined fw
%
%         roach_connected = 1;
%
%         % As per Dr. Barott
%         global_pause = 0.25; % Pause to enforce between writesSELECTOR_TWO_REG1
%
%     catch
%     end
% end

% Create Message Data
message_signal = CreateMessageData();

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
