function [ subframe_2_300_bits ] = GenerateSubframe2( ...
    GPS_week_number, TOW_truncated, D_star  )
    % ----------------------------------------------------------------------- %
    %  GenerateSubframe2 - Generates the second subframe of a GPS Message. It %
    %   contains 300 bits, 10 words each 30 bits. The following define each   %
    %   bit content:                                                          %
    %                                                                         %
    %       Word 1 - TLM                                                      %
    %       Word 2 - HOW                                                      %
    %       Word 3 - IODE (8-bits), C_rs (16-bits)                            %
    %       Word 4 - Delta_n (16-bits), M_not (MSB, 8-bits)                   %
    %       Word 5 - M_not(LSB 24-bits)                                       %
    %       Word 6 - C_US (16-bits), e (MSB, 9-bits)                          %
    %       Word 7 - e (LSB, 24-bits)                                         %
    %       Word 8 - C_US (16 bits), Root_a (MSB, 8-bits)                     %
    %       Word 9 - Root_a (LSB, 24-bits)                                    %
    %       Word 10 - t_oe (16-bits,), Fit Interval Flag (1-bit),AODO(5-bits) %
    %                                                                         %
    %                                                                         %
    %       INPUT:                                                            %
    %         - GPS_week_number - A 10-bit MSB of the 29-bit z-count          %
    %         - TOW_truncated - 17 MSB of 19 bit time of week                 %
    %         - D_star -  Last two bits of previews word                      %
    %                                                                         %
    % ----------------------------------------------------------------------- %
    %               Created by Kurt Pedrosa  -- March 02th 2017               %
    %                                                                         %
    %      CHANGE LOG:                                                        %
    %                                                                         %
    %   + by Kurt: Values for IODE, C_rs, Delta_n M_not changed to real       %
    % observed values from:                                                   %
    %   http://www.colorado.edu/geography/gcraft/notes/gps/ephclock.html      %
    %                           March 10th 2017                               %
    % ----------------------------------------------------------------------- %

    % Define Frame
    frame_id = [ 0 1 0 ];

    % Check TOW truncated
    if length(TOW_truncated) ~= 17
        error(' Invalid Time Of Week - Subframe 1 ');
    end

    % Define all  300 bits, 10 words.
    word_1  = GenerateTLMWord( D_star );
    word_2  = GenerateHOWWord( TOW_truncated, frame_id, word_1( 29:30 ));
    word_3  = GenerateWord3( word_2( 29:30 ) );
    word_4  = GenerateWord4( word_3(29:30) );
    word_5  = GenerateWord5( word_4(29:30) );
    word_6  = GenerateWord6( word_5(29:30) );
    word_7  = GenerateWord7( word_6(29:30) );
    word_8  = GenerateWord8( word_7(29:30) );
    word_9  = GenerateWord9( word_8(29:30) );
    word_10 = GenerateWord10( word_9(29:30) );

    % Returns a array of 10 x 30 bits
    %   Each row is a word. For example
    %      + To access word 8 - subframe_1_300_bits( 8, : )
    %      + To access word 10 bit 29 and 30  - subframe_1_300_bits( 10, (29:30) );
    subframe_2_300_bits = [ word_1 ;
                            word_2 ;
                            word_3 ;
                            word_4 ;
                            word_5 ;
                            word_6 ;
                            word_7 ;
                            word_8 ;
                            word_9 ;
                            word_10];
end


function word_3 = GenerateWord3( D_star )
% --------------------------------------------------------------------------- %
% GenerateWord3() - Generates a 30 bit word containing IODE (Issure of Data   %
%   Ephemeris), and C_rs ( Amplitude of the Sine harmonic correction term to  %
%   the Orbit Radius ),  and Parity bits,                                     %
%                                                                             %
%   Inputs:     D_star - Bits 29 and 30 of word 2                             %
% --------------------------------------------------------------------------- %
    % Define IODE ( Issue of Data (Ephemeris) )
    %   This provides the user with a convenient means for detecting
    %   any change in the ephemirs represenation parameters.
    % Note: IODE is provided in both Subframe 2 and 3 for the purpose of
    %       comparison.
    % IMPORTANT: IODE is compared to the 8 LSB of the IODC in subframe 1.
    %       If the three terms ( IODE subframe 2 and 3, and IODC subframe
    %       1 ) do NOT match, a set curover has occurred and new data
    %       must be collected.
    %       Timing and constrained defined in Paragraph 20.3.4.4
    %   For Simulation IDOE = 157 = 10011101b
    IDOE = [ 1 0 0 1 1 1 0 1 ];

    % Define C_rs
    %   C_rs is the Amplitude of the Sine Harmonic Correction Term to
    %       the Orbit Radius.
    %   The equation Radius Correction:
    %       delta_r_k = C_rs sin( 2 phi_k ) + C_rc Cos ( 2 phi_k )
    %
    %   Note: C_rc and C_rs sensitivity of position is about one meter/meter
    %
    %  C_rs has a scale Factor of 2^-5. There for:
    %       5 meter = 5/(2^-5) = 160 meter
    %       160 Dec = 0000000010100000 Binary
    %
    %       175.406 meter = 175.406/(2^-5) = 5.6130e3 meter
    %       5613 Dec = 0001010111101101 Binray

    C_rs = [ 0 0 0 1 0 1 0 1 1 1 1 0 1 1 0 1 ]; % 175.406 meter
    % C_rs = [ 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0]; % 1 meter

    % Pack'em all into a 24-bit number
    word_3_no_parity = ...
        [ IODE C_rs ];

    word_3 = [ word_3_no_parity GpsParityMaker( 0, word_3_no_parity, D_star ) ];
end

function word_4 = GenerateWord4( D_star )
% ------------------------------------------------------------------------%
% GenerateWord4() - Generates a 30 bit word containg Delta_n (16-bits),
%    M_zero (MSB, 8-bits)  , and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 3
% ------------------------------------------------------------------------%

    % Define Delta_n
    %   delta_n is the Mean MOtion Difference From Caputed Value
    %   delta_n has 16 bits and a Scale Factor of 2^-43
    %   FOR SIMULATION: Zero Mean Motion Difference:
    %       delta_n = 0 semi-circles/sec = 0/2^-43 = 0 semi-circles/sec
    %       delta_n = 4.1616E-09 rad/sec = 1.3247e-9 semi-circles/sec
    %       = 0010110110000011b
    %   Note: 1 sem-circle = 3.1415926535 radian
    delta_n = [ 0 0 1 0 1 1 0 1 1 0 0 0 0 0 1 1 ];


    % Define M_not
    %   M_not is the Mean Anomaly at Reference Time
    %   M_not has 32 bits ( 8-bits in word 4 of Subframe 2 )
    %   M_not has a Scale Factor of 2^-31
    %   M_not = 0 semi-circles = 0/(2^-31) = 0 semi-circles
    %   M_not = 1.41596 rad = 0.4507140664408 semi-circles ...
    %       = 0.4507140664408/(2^-31) = 9.6790 e8
    %       = 00111001 101100001111111110011111 binary
    %   Note: 1 sem-circle = 3.1415926535 radians
    M_not_MSB = [ 0 0 1 1 1 0 0 1 ]; % MSB

    % Pack'em all into a 24-bit number
    word_4_no_parity = ...
        [ delta_n M_not_MSB ];

    word_4 = [ word_4_no_parity ...
        GpsParityMaker( 0, word_4_no_parity, D_star ) ];
end

function word_5 = GenerateWord5( D_star )
% ------------------------------------------------------------------------%
% GenerateWord5() - Generates a 30 bit word containg M_zero (LSB, 24-bits)  ,
% and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 4
% ------------------------------------------------------------------------%
    % Define M_not
    %   M_not is the Mean Anomaly at Reference Time
    %   M_not has 32 bits ( 24-bits in word 5 of Subframe 2 )
    %   M_not has a Scale Factor of 2^-31
    %   M_not = 0 semi-circles = 0/(2^-31) = 0 semi-circles
    %   M_not = 1.41596 rad = 0.4507140664408 semi-circles ...
    %       = 0.4507140664408/(2^-31) = 9.6790 e8
    %       = 00111001 msb 101100001111111110011111 lsb binary
    %   Note: 1 sem-circle = 3.1415926535 radians
    M_not_LSB = [ 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 0 0 1 1 1 1 1 ];


    word_5_no_parity = M_not_LSB ;

    word_5 = [ word_5_no_parity ...
        GpsParityMaker( 0, word_5_no_parity, D_star ) ];
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

    word_6 = [ word_6_no_parity ...
        GpsParityMaker(0,  word_6_no_parity, D_star ) ];
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

    word_7 = [ word_7_no_parity ...
        GpsParityMaker( 0, word_7_no_parity, D_star ) ];
end

function word_8 = GenerateWord8( D_star )
% ------------------------------------------------------------------------%
% GenerateWord8() - Generates a 30 bit word containg , IODC LSB 8 bits,
%   T_oc SV clock correction, and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 7
% ------------------------------------------------------------------------%
    % Bits 1 thru 8 are the LSB of the IODC. the 2 MSB of the IODC are
    %   sent on word 3 of subframe 1. As per this project, all IODC
    %   bits have been set to 0.
    IODC_LSB_8_bits = [ 0 0 0 0 0 0 0 0 ];

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

    word_8 = [ word_8_no_parity ...
        GpsParityMaker( 0, word_8_no_parity, D_star ) ];
end

function word_9 = GenerateWord9( D_star )
% ------------------------------------------------------------------------%
% GenerateWord8() - Generates a 30 bit word containg , SV clock correction
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
    clock_correction_a_f2 = [ 0 0 0 0 0 0 0 0];
    clock_correction_a_f1 = [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];

    word_9_no_parity = [clock_correction_a_f2 clock_correction_a_f1 ];

    word_9 = [ word_9_no_parity ...
        GpsParityMaker( 0, word_9_no_parity, D_star ) ];
end

function word_10 = GenerateWord10( D_star )
% ------------------------------------------------------------------------%
% GenerateWord8() - Generates a 30 bit word containg , SV Clock correction
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
    clock_correction_a_f0 = ...
        [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];

    word_10_no_parity = clock_correction_a_f0;

    word_10 = [ word_10_no_parity ...
        GpsParityMaker( 1, word_10_no_parity, D_star ) ];
end
