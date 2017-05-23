function [ subframe_1_300_bits ] = GenerateSubframe1( ...
    GPS_week_number, TOW_truncated, sv_health, sv_af0, sv_af1, D_star  )
% ----------------------------------------------------------------------- %
%  GenerateSubframe1 - Generates the first subframe of a GPS Message. It  %
%   contains 300 bits, 10 words each 30 bits. The following define each   %
%   bit content:
%       Word 1 - TLM
%       Word 2 - HOW
%       Word 3 - Week Number, P/CA bit , URA Index, SV Health, IODC
%       Word 4 - Data Flag for L2 PCode, Reserve bits
%
%
%       INPUT:                                                            %
%         - GPS_week_number - A 10-bit MSB of the 29-bit z-count          %
%         - TOW_truncated - 17 MSB of 19 bit time of week
%         - D_star -  Last two bits of previews word
%                                                                         %
% ----------------------------------------------------------------------- %
%               Created by Kurt Pedrosa  -- Feb 20th 2017                 %
%                                                                         %
%      CHANGE LOG:                                                        %
%                                                                         %
%   + by Kurt: Values for IODC changed to real observed values from:      %
%   http://www.colorado.edu/geography/gcraft/notes/gps/ephclock.html      %
%                           March 10th 2017                               %
% ----------------------------------------------------------------------- %
% ----------------------------------------------------------------------- %

% Define Frame
frame_id = [ 0 0 1 ];

% Define all  300 bits, 10 words.
word_1  = GenerateTLMWord( D_star );
word_2  = GenerateHOWWord( TOW_truncated, frame_id, word_1( 29:30 ));
word_3  = GenerateWord3( GPS_week_number, sv_health, word_2( 29:30 ) );
word_4  = GenerateWord4( word_3(29:30) );
word_5  = GenerateWord5( word_4(29:30) );
word_6  = GenerateWord6( word_5(29:30) );
word_7  = GenerateWord7( word_6(29:30) );
word_8  = GenerateWord8( word_7(29:30) );
word_9  = GenerateWord9( sv_af1, word_8(29:30) );
word_10 = GenerateWord10( sv_af0, word_9(29:30) );

% Returns a array of 10 x 30 bits
%   Each row is a word. For example
%      + To access word 8 - subframe_1_300_bits( 8, : )
%      + To access word 10 bit 29 and 30  - subframe_1_300_bits( 10, (29:30) );
subframe_1_300_bits = [ word_1 ;
                        word_2 ;
                        word_3 ;
                        word_4 ;
                        word_5 ;
                        word_6 ;
                        word_7 ;
                        word_8 ;
                        word_9 ;
                        word_10];

% subframe_1_300_bits = [ word_10 ;
%                         word_9 ;
%                         word_8 ;
%                         word_7 ;
%                         word_6 ;
%                         word_5 ;
%                         word_4 ;
%                         word_3 ;
%                         word_2 ;
%                         word_1];
end


function word_3 = GenerateWord3( GPS_week_number, sv_health, D_star )
% ------------------------------------------------------------------------%
% GenerateWord3() - Generates a 30 bit word containing Week Number,
%   P/CA bit , URA Index, SV Health, Issue of Data, and Parity bits.
%
%   Inputs:     GPS_week_number - 10 MSB of the z-count
%               D_star - Bits 29 and 30 of word 2
% ------------------------------------------------------------------------%

    % Check GPS_week_number
    if length(GPS_week_number) ~= 10
        error(' Invalid GPS week number - Subframe 1 - Word 3 ');
    end

    % Define L2 code flag
    %   00 = Reserved
    %   01 = P code ON
    %   10 = C/A code ON
    Code_L2_Flag = [1 0];

    % Define URA Index ( 0 thru 15 - 4 bits )
    %   0  = URA is between 0.00 and 2.40 meters - BEST
    %   14 = URA is between 3072.00 and 6144.00 meters - WORST
    %   15 = no Data
    URA_index = [0 0 0 0];

    % Define SV Health. MSB (bit 17) indicates summary of health:
    %   0 = all NAV data are OK
    %   1 = some or all NAV data are bad
    % Other 5 bits indicate health of singal components. For this project
    % all health bits are set to '0' indicating a healthy signal
    if sv_health == 0
        health = [ 0 0 0 0 0 0 ];
    else
        health = dec2bin( health, 6);
    end

    % Define IODC
    % Bits 1 thru 8 are the LSB of the IODC. the 2 MSB of the IODC are
    %   sent on word 3 of subframe 1. As per this project, all IODC
    %   bits have been set to 0.
    %   This provides the user with a convenient means for detecting
    %   any change in the ephemirs represenation parameters.
    % Note: IODE is provided in both Subframe 2 and 3 for the purpose of
    %       comparison.
    % IMPORTANT: IODE is compared to the 8 LSB of the IODC in subframe 1.
    %       If the three terms ( IODE subframe 2 and 3, and IODC subframe
    %       1 ) do NOT match, a set curover has occurred and new data
    %       must be collected.
    %       Timing and constrained defined in Paragraph 20.3.4.4
    %   For Simulation IODC = 157 = 0010011101b
    % Therefo IODC in word 3 of subframe 1 MUST be 00
    IODC = [0 0];

    % Pack'em all into a 24-bit number
    word_3_no_parity = ...
        [ GPS_week_number Code_L2_Flag URA_index health, IODC ];

    word_3 = GpsParityMaker( 0, word_3_no_parity, D_star ) ;
end

function word_4 = GenerateWord4( D_star )
% ------------------------------------------------------------------------%
% GenerateWord4() - Generates a 30 bit word containg Data Flag for L2 PCode,
%   Reserve bits, and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 3
% ------------------------------------------------------------------------%
    % Data Flag for L2 P-Code
    %   'When bit 1 of ward four is a "1", it shall indicate that
    %   the NAV data stream was commanded OFF on the P-code of the L2 Chn.
    L2_P_code_flag = 1;

    % Bits 2 thru 24 are Reserved
    % As per SPS Signal Spec NAVSTAR 2nd edition Jun 2 1995
    %   reserved bits in subframe 2 are:
    %   'All spare and reserved data fields support valid parity within
    %   thier respective words. Contents of spare data field are
    %   alternating ones and zeros until they are allocated for a new
    %   function.' See Table 2-6

    reserved_bits = [ 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1];

    word_4_no_parity = ...
        [ L2_P_code_flag reserved_bits ];

    word_4 = GpsParityMaker( 0, word_4_no_parity, D_star );
end

function word_5 = GenerateWord5( D_star )
% ------------------------------------------------------------------------%
% GenerateWord5() - Generates a 30 bit word containg , Reserve bits,
%   and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 4
% ------------------------------------------------------------------------%
    % Bits 1 thru 24 are Reserved
    % As per SPS Signal Spec NAVSTAR 2nd edition Jun 2 1995
    %   reserved bits in subframe 2 are:
    %   'All spare and reserved data fields support valid parity within
    %   thier respective words. Contents of spare data field are
    %   alternating ones and zeros until they are allocated for a new
    %   function.' See Table 2-6

    reserved_bits = [ 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0];

    word_5_no_parity = reserved_bits ;

    word_5 = GpsParityMaker( 0, word_5_no_parity, D_star );
end

function word_6 = GenerateWord6( D_star )
% ------------------------------------------------------------------------%
% GenerateWord6() - Generates a 30 bit word containg , Reserve bits,
%   and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 5
% ------------------------------------------------------------------------%
    % Bits 1 thru 24 are Reserved
    % As per SPS Signal Spec NAVSTAR 2nd edition Jun 2 1995
    %   reserved bits in subframe 2 are:
    %   'All spare and reserved data fields support valid parity within
    %   thier respective words. Contents of spare data field are
    %   alternating ones and zeros until they are allocated for a new
    %   function.' See Table 2-6

    reserved_bits = [ 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0];

    word_6_no_parity = reserved_bits ;

    word_6 = GpsParityMaker(0,  word_6_no_parity, D_star );
end

function word_7 = GenerateWord7( D_star )
% ------------------------------------------------------------------------%
% GenerateWord7() - Generates a 30 bit word containg , Reserve bits,
%   SV clock correction T GD, and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 6
% ------------------------------------------------------------------------%
    % Bits 1 thru 16 are Reserved
    % As per SPS Signal Spec NAVSTAR 2nd edition Jun 2 1995
    %   reserved bits in subframe 2 are:
    %   'All spare and reserved data fields support valid parity within
    %   thier respective words. Contents of spare data field are
    %   alternating ones and zeros until they are allocated for a new
    %   function.' See Table 2-6

    reserved_bits = [ 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0];

    % As Per GPS System Engineering and Integration Interfeace Specs
    %   IS-GPS-200 - NAVSTAR GPS Space Segment/Navigation User
    %   Segment Interface - 28 Jul 16:
    %   'Bits 17 through 24 of word seven contain the L1-L2 correctoin
    %   term, T_gd, for the benefit of "L1 only" or "L2 only" users.
    %   the related user algorithm is given in paragraph 20.3.3.3.'
    %  NOTE: For thos project these bits are set to zero. Meaning...
    %   there are no correction needed.
    message_correction_t_gd = [ 0 0 0 0 0 0 0 0 ];

    word_7_no_parity = [reserved_bits message_correction_t_gd ];

    word_7 = GpsParityMaker( 0, word_7_no_parity, D_star );
end

function word_8 = GenerateWord8( D_star )
% ------------------------------------------------------------------------%
% GenerateWord8() - Generates a 30 bit word containg , IODC LSB 8 bits,
%   T_oc SV clock correction, and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 7
% ------------------------------------------------------------------------%
% Define IODC
% Bits 1 thru 8 are the LSB of the IODC. the 2 MSB of the IODC are
%   sent on word 3 of subframe 1. As per this project, all IODC
%   bits have been set to 0.
%   This provides the user with a convenient means for detecting
%   any change in the ephemirs represenation parameters.
% Note: IODE is provided in both Subframe 2 and 3 for the purpose of
%       comparison.
% IMPORTANT: IODE is compared to the 8 LSB of the IODC in subframe 1.
%       If the three terms ( IODE subframe 2 and 3, and IODC subframe
%       1 ) do NOT match, a set curover has occurred and new data
%       must be collected.
%       Timing and constrained defined in Paragraph 20.3.4.4
%   For Simulation IODC = 157 = 0010011101b
% Therefo IODC in word 8 of subframe 1 MUST be 10011101
IODC_LSB_8_bits = [ 1 0 0 1 1 1 0 1 ];

    % As Per GPS System Engineering and Integration Interfeace Specs
    %   IS-GPS-200 - NAVSTAR GPS Space Segment/Navigation User
    %   Segment Interface - 28 Jul 16:
    %   20.3.3.3.1.8 SV Clock Correction:
    %       Bits 9 through 24 of word eight ... contain the parameter
    %       needed by the users for apparent SV clock correction.
    %     Note: toc - 9 thru 24 bits of word 8 - subframe 1
    %           af2 - 1 thru 8 bits of word 9 - subframe 1
    %           af1 - 9 thru 24 bits of word 9 - subframe 1
    %           af0 - 1 thru 22 bits of word 10 - subrame 1
    % NOTE: For this project these bits are set to zero. Meaning...
    %   no correction is needed.
    clock_correction_t_oc = [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];

    word_8_no_parity = [IODC_LSB_8_bits clock_correction_t_oc ];

    word_8 = GpsParityMaker( 0, word_8_no_parity, D_star );
end

function word_9 = GenerateWord9( sv_af1, D_star )
% ------------------------------------------------------------------------%
% GenerateWord9() - Generates a 30 bit word containg , SV clock correction
%   term A_f2 and A_f1 and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 8
% ------------------------------------------------------------------------%
    % As Per GPS System Engineering and Integration Interfeace Specs
    %   IS-GPS-200 - NAVSTAR GPS Space Segment/Navigation User
    %   Segment Interface - 28 Jul 16:
    %   20.3.3.3.1.8 SV Clock Correction:
    %       Bits 9 through 24 of word eight ... contain the parameter
    %       needed by the users for apparent SV clock correction.
    %     Note: toc - 9 thru 24 bits of word 8 - subframe 1
    %           af2 - 1 thru 8 bits of word 9 - subframe 1
    %           af1 - 9 thru 24 bits of word 9 - subframe 1
    %           af0 - 1 thru 22 bits of word 10 - subrame 1
    % NOTE: For this project these bits are set to zero. Meaning...
    %   no correction is needed.
    a_f2 = [ 0 0 0 0 0 0 0 0];
    % Get af1 scaled
    a_f1 = SvData2Binary( sv_af1/( 2^-43 ), 16);

    word_9_no_parity = [a_f2 a_f1 ];

    word_9 = GpsParityMaker( 0, word_9_no_parity, D_star );
end

function word_10 = GenerateWord10( sv_af0, D_star )
% ------------------------------------------------------------------------%
% GenerateWord10() - Generates a 30 bit word containg , SV Clock correction
%   term A_F0, Noninformation bearing bits for Parity comp, and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 9
% ------------------------------------------------------------------------%
    % As Per GPS System Engineering and Integration Interfeace Specs
    %   IS-GPS-200 - NAVSTAR GPS Space Segment/Navigation User
    %   Segment Interface - 28 Jul 16:
    %   20.3.3.3.1.8 SV Clock Correction:
    %       Bits 9 through 24 of word eight ... contain the parameter
    %       needed by the users for apparent SV clock correction.
    %     Note: toc - 9 thru 24 bits of word 8 - subframe 1
    %           af2 - 1 thru 8 bits of word 9 - subframe 1
    %           af1 - 9 thru 24 bits of word 9 - subframe 1
    %           af0 - 1 thru 22 bits of word 10 - subrame 1
    % NOTE: For this project these bits are set to zero. Meaning...
    %   no correction is needed.
    a_f0 = SvData2Binary( sv_af0/( 2^-31 ), 22);

    word_10_no_parity = a_f0;

    word_10 = GpsParityMaker( 1, word_10_no_parity, D_star );
end
