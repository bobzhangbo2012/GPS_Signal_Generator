function [ subframe_3_300_bits ] = GenerateSubframe3( ...
    GPS_week_number, TOW_truncated, D_star  )
    % ----------------------------------------------------------------------- %
    %  GenerateSubframe3 - Generates the second subframe of a GPS Message. It %
    %   contains 300 bits, 10 words each 30 bits. The following define each   %
    %   bit content:                                                          %
    %                                                                         %
    %       Word 1 - TLM                                                      %
    %       Word 2 - HOW                                                      %
    %       Word 3 - C_ic (16-bits), omega_not ( 8-bits MSB )                 %
    %       Word 4 - omega_not (24-bits LSB)                                  %
    %       Word 5 - C_is ( 26-bits), i_not ( 8 bits MSB )                    %
    %       Word 6 - i_not (24-bits LSB )                                     %
    %       Word 7 - C_rc (16-bits), omega (8-bits MSB)                       %
    %       Word 8 - omega (24 bits LSB)                                      %
    %       Word 9 - omega_dot ( 24-bits)                                    %
    %       Word 10 - IODE (8-bits,), IDOT (14-bit),AODO(5-bits) %
    %                                                                         %
    %                                                                         %
    %       INPUT:                                                            %
    %         - GPS_week_number - A 10-bit MSB of the 29-bit z-count          %
    %         - TOW_truncated - 17 MSB of 19 bit time of week                 %
    %         - D_star -  Last two bits of previews word                      %
    %                                                                         %
    % ----------------------------------------------------------------------- %
    %               Created by Kurt Pedrosa  -- March 03th 2017               %
    %                                                                         %
    %      CHANGE LOG:                                                        %
    %                                                                         %
    %   + by Kurt: Values for IODE, C_ic, omega_not, C_is, i_not, C_rc, omega %
    %   omega_dot, IODE, IDOT, and  AODO changed to real observed values from:%
    %   http://www.colorado.edu/geography/gcraft/notes/gps/ephclock.html      %
    %                           March 10th 2017                               %
    % ----------------------------------------------------------------------- %

    % Define Frame
    frame_id = [ 0 1 1 ];

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
    subframe_3_300_bits = [ word_1 ;
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
% GenerateWord3() - Generates a 30 bit word containing  C_ic (16-bits),       %
%  omega_not ( 8-bits MSB )    and Parity bits,                               %
%                                                                             %
%   Inputs:     D_star - Bits 29 and 30 of word 2                             %
% --------------------------------------------------------------------------- %
    % Define C_ic
    % C_ic is the Amplitude of the Cosine Harmonic Correction Term to the Orbit
    %   Radius
    % C_ic has 16 bits, and a Scale Factor of 2^-29, and measured in radians
    % The Inclination Correction equation is:
    %   delta_i_k = c_is sin(2phi_k) + c_ic cos(2phi_k)
    %       found in Table 20-IV
    %
    %   C_ic = 1.88127E-07 = 1.88127E-07/2^-29 = 100.9999
    %   0000000001100100b
    C_ic = [ 0 0 0 0 0 0 0 0 0 1 1 0 0 1 0 0 ];

    % Define omega_not
    % omega_not is the Longitude of Ascending Node of Orbit Plane at Weekly Epoch
    % omega_not is 32-bit ( 8 bits MSB )
    % omega_not has a Scale Factor of 2^-31 and measured in semi-circles
    % Note: No observed date was found online. Value of zero chosen for simulation
    %   omega_not = 0 = 0/2^-31 = 0 = 00000000 MSB 000000000000000000000000b
    omega_not_msb = [ 0 0 0 0 0 0 0 0 ];

    % Pack'em all into a 24-bit number
    word_3_no_parity = [ C_ic omega_not_msb ];

    word_3 = [ word_3_no_parity GpsParityMaker( 0, word_3_no_parity, D_star ) ];
end

function word_4 = GenerateWord4( D_star )
% ------------------------------------------------------------------------%
% GenerateWord4() - Generates a 30 bit word containg omega_not (24-bits LSB)
%    , and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 3
% ------------------------------------------------------------------------%

    % Define omega_not
    % omega_not is the Longitude of Ascending Node of Orbit Plane at Weekly Epoch
    % omega_not is 32-bit ( 8 bits MSB )
    % omega_not has a Scale Factor of 2^-31 and measured in semi-circles
    % Note: No observed date was found online. Value of zero chosen for simulation
    %   omega_not = 0 = 0/2^-31 = 0 = 00000000 MSB 000000000000000000000000 LSB
    omega_not_lsb = [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];

    % Pack'em all into a 24-bit number
    word_4_no_parity = omega_not_lsb ;

    word_4 = [ word_4_no_parity ...
        GpsParityMaker( 0, word_4_no_parity, D_star ) ];
end

function word_5 = GenerateWord5( D_star )
% ------------------------------------------------------------------------%
% GenerateWord5() - Generates a 30 bit word containg C_is ( 26-bits),
%   i_not ( 8 bits MSB ) and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 4
% ------------------------------------------------------------------------%
    % Define C_is
    % C_is is the Amplitude of the Cosine Harmonic Correction Term to the
    %   Angle of Inclination
    % C_is is a 16 bit number with a Scale Factor of 2^-29. Units of radians.
    % The Inclination Correction equation is:
    %   delta_i_k = c_is sin(2phi_k) + c_ic cos(2phi_k)
    %       found in Table 20-IV
    %   C_is = -1.00583E-07 = -1.00583E-07/2^-29 = -54.001 =
    %   0000000000110110 b ( Positive )
    %   1111111111001010 b ( Negative )
    C_is = [ 1 1 1 1 1 1 1 1 1 1 0 0 1 0 1 0 ];

    % Define i_not
    % i_not is the Inclination Angle at Reference Time.
    % i_not has 32-bits and a Scale Factor of 2^-31. Units of semi-circles.
    % The Corrected Inclination equation:
    %       i_k = i_not + delta_i_k + (IDOT)t_k
    %           found in Table 20-IV
    %  0.950462 rad = 0.3025 semi-circles = 0.3025/2^-31
    %   00100110 msb 101110000101000111101011 lsb
    i_not_msb = [ 0 0 1 0 0 1 1 0 ];

    % Pack'em all into a 24-bit number
    word_5_no_parity = [ C_is i_not_msb ];

    word_5 = [ word_5_no_parity ...
        GpsParityMaker( 0, word_5_no_parity, D_star ) ];
end

function word_6 = GenerateWord6( D_star )
% ------------------------------------------------------------------------%
% GenerateWord6() - Generates a 30 bit word containg ,C_UC (16-bits),
% eccentricity (MSB, 8-bits) and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 5
% ------------------------------------------------------------------------%

    % Define i_not
    % i_not is the Inclination Angle at Reference Time.
    % i_not has 32-bits and a Scale Factor of 2^-31. Units of semi-circles.
    % The Corrected Inclination equation:
    %       i_k = i_not + delta_i_k + (IDOT)t_k
    %           found in Table 20-IV
    %  0.950462 rad = 0.3025 semi-circles = 0.3025/2^-31
    %   00100110 msb 101110000101000111101011 lsb
    i_not_lsb = [ 1 0 1 1 1 0 0 0 0 1 0 1 0 0 0 1 1 1 1 0 1 0 1 1 ];

    % Pack'em all into a 24-bit number
    word_6_no_parity = i_not_lsb;

    word_6 = [ word_6_no_parity ...
        GpsParityMaker(0,  word_6_no_parity, D_star ) ];
end

function word_7 = GenerateWord7( D_star )
% ------------------------------------------------------------------------%
% GenerateWord7() - Generates a 30 bit word containg C_rc (16-bits) and  omega (8-bits MSB)
% and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 6
% ------------------------------------------------------------------------%

    % Pack'em all into a 24-bit number
    word_7_no_parity = ;

    word_7 = [ word_7_no_parity ...
        GpsParityMaker( 0, word_7_no_parity, D_star ) ];
end

function word_8 = GenerateWord8( D_star )
% ------------------------------------------------------------------------%
% GenerateWord8() - Generates a 30 bit word containg ,C_US (16 bits),
% sqrt_a (MSB, 8-bits)  and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 7
% ------------------------------------------------------------------------%

    % Define C_US
    % C_US is the Amplitude of the Sine Hamronic Correction Term to the
    %   Argument of Latitude
    % C_US is in radians, has 16-bits and a Scale Factor of 2^-29
    %       C_UC =  1.06301E-05 =  1.06301E-05/2^-29 = 5.7070e+03
    %       0001011001001010b
    C_US = [ 0 0 0 1 0 1 1 0 0 1 0 0 1 0 1 0 ];

    % Define sqrt_a
    % sqrt_a is the Square Root of the Semi-Major Axis
    % sqrt_a has 32 bits (8-bit MSB in word 9 Subframe 2)
    % sqrt_a is the squar root of a meter and has a Scale Factor of 2^-19
    % sqrt_a has a range of 2530 to 8192
    %   5153.79 = 5153.79/2^-19 = 2.7021e+09 = 10100001 msb 000011100101000111101011 lsb
    sqrt_a_dec = 5153.79;

    % Check range
    % Note from the author: "Again, checking range twice. I don't like it!" -kp
    if sqrt_a_dec < 2530 || sqrt_a_dec > 8192
        error('Squre Root of the Semi-Major Axis is out-of-range. Check Word 8 of Subframe 2.');
    else
        sqrt_a = str2bin_array( dec2bin( sqrt_a_dec/2^-19, 32 ) );
        sqrt_a = sqrt_a( 1:8 );
    end

    % Pack'em all into a 24-bit number
    word_8_no_parity = [ C_US sqrt_a ];

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
    % Define sqrt_a
    % sqrt_a is the Square Root of the Semi-Major Axis
    % sqrt_a has 32 bits (8-bit MSB in word 9 Subframe 2)
    % sqrt_a is the squar root of a meter and has a Scale Factor of 2^-19
    % sqrt_a has a range of 2530 to 8192
    %   5153.79 = 5153.79/2^-19 = 2.7021e+09 = 10100001 msb 000011100101000111101011 lsb
    sqrt_a_dec = 5153.79;

    % Check range
    % Note from the author: "Again, checking range twice. I don't like it!" -kp
    if sqrt_a_dec < 2530 || sqrt_a_dec > 8192
        error('Squre Root of the Semi-Major Axis is out-of-range. Check Word 9 of Subframe 2.');
    else
        sqrt_a = str2bin_array( dec2bin( sqrt_a_dec/2^-19, 32 ) );
        sqrt_a = sqrt_a( 9:end );
    end

    % Pack'em all into a 24-bit number
    word_9_no_parity = [ sqrt_a ];

    word_9 = [ word_9_no_parity ...
        GpsParityMaker( 0, word_9_no_parity, D_star ) ];
end

function word_10 = GenerateWord10( D_star )
% ------------------------------------------------------------------------%
% GenerateWord8() - Generates a 30 bit word containg , t_oe (16-bits,),
% Fit Interval Flag (1-bit),AODO(5-bits) and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 9
% ------------------------------------------------------------------------%

    % Define t_oe
    % t_oe is Reference Time Ephemeris ( for more info go to paragraph 20.3.4.5 )
    % t_oe has 16 bits and a Scale Factor of 2^4.
    % t_oe is counted in units of seconds.
    % t_oe has a range of 0 to 604,784 seconds.
    %   252000 = 25200/2^4 = 1575 = 0000011000100111
    t_oe_dec = 252000;

    if t_oe_dec < 0 || t_oe_dec > 604784
        error('Reference Time Ephemeris is out-of-range. Check Word 10 of Subframe 2.');
    else
        t_oe = str2bin_array( dec2bin( t_oe_dec/2^4, 16 ) )
    end

    % Define Fit Interval Flag
    % A "fit interval" flag indicates whether the ephemerides are based on a
    %   4-hour fit interval or a Greater than 4-hours.
    % Paragraph 6.2.3 defines the following operational intervals:
    %       Normal - SV normal ops: fit flag = 0 ( ref. 20.3.3.4.3.1)
    %       Short-term Extended: fit flag = 1 & IODE < 240 ( ref. 20.3.4.4 )
    %       Long-term Extended: fit flag = 1 & IODE between 240-255
    fit_interval_flag = 0 % 4-hours fit interval
    %fit_interval_flag = 1; % >4-hours fit interval

    % Define AODO
    % aodo is the Age of Data Offset. Is a term used for teh Navigation Message
    %   Correction table ( NMCT ) contained in subframe 4 ( ref 20.3.3.5.1.9 )
    % aodo enables the user to determine the validity time for the NMCT Data
    %   provided in subframe 4 of the transmitting SV. Algorithm given in 20.3.3.4.4
    % aodo is 5-bits unsigned term w/ an LSB Scale Factor of 900
    % aodo has a range between 0 and 31.
    % aodo has units of seconds.
    % In paragraph 20.3.3.4.4 NMCT Validity time states :
    %   If AODO term is 27900 ( 11111 binary ) then NMCT data is invalid.
    %   if AODO term is less than 27900 then user shall compute the validity
    %       time for NMCT ( t_nmct ) using the t_oe and aodo term.
    %
    %   OFFSET = t_oe [ modulo 7200 ]
    %   if OFFEST == 0 then t_nmct = t_oe - aodo
    %   if OFFSET > 0  then t_nmct = t_oe - OFFSET + 7200 - AODO
    aodo = [ 0 0 0 0 0 ]

    % Pack'em all into a 22-bit number THIS HAS FORCE PARITY!
    word_10_no_parity = [ t_oe fit_interval_flag aodo ];

    word_10 = [ word_10_no_parity ...
        GpsParityMaker( 1, word_10_no_parity, D_star ) ];
end
