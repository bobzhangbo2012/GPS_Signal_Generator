function [ HOW_word ] = GenerateHOWWord( TOW_bin, frame_ID, D_star )
% ----------------------------------------------------------------------- %
%     GenerateTLMWOrd - Generates all 30 bits of the HOW word. The HOW    %
%  or Handover Word is ALWAYS the second word on a subframe. It follows   %
%  the TLM word. It begins with the 17-bits of the TOW (time-of-week)     %
%  count. NOTE that the full TOW is 17-bits which are the LSB of the      %
%  29-bit z-count. After the TOW count is an ALERT flag, when this flag   %
%  is set to '1' is indicates that the User Range Accurcy (URE) is worse  %
%  than indicated and that the receiver shall use the SV at own risk.     %
%  Bit 19 is an anti-spoof flag. A '1' inidactest that the A-S mode is on.%
%  Bit 20 to 22 is the subframe ID, 1 thru 5.                             %
%                                                                         %
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ %
% +          TOW - truncated          | Flg | Frame | Xsm |    Parity   + %
% + x x x x x x x x x x x x x x x x x | 0 0 | x x x | x x | x x x x x x + %
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ %
%   1                                   18    20     23   25              %
%                                                                         %
% ----------------------------------------------------------------------- %
%               Created by Kurt Pedrosa  -- Feb 20th 2017                 %
% ----------------------------------------------------------------------- %

    % Define flags
    Alert_flag = 0;
    Anti_spoof_flag = 0;

    % Check flags
    if length(Alert_flag) ~= 1 || length(Anti_spoof_flag) ~= 1
        error( ' Alert Flag or Anti Spoofing Flag is incorrect ' );
    end

    % Check for TOW is done outside this function
    % Pack'em all into a 22-bit number
    HOW_word = [ TOW_bin, Alert_flag, Anti_spoof_flag, frame_ID ];

    % Bits 23 and 24 have to be calculated so that bits 29 and 30 are '0'
    % A parity calculation have to be calculated in order that bits
    % 23 to 30 are generated.
    HOW_word = GpsParityMaker( 1, HOW_word, D_star ) ;
end
