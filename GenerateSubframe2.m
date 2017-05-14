function [ subframe_2_300_bits ] = GenerateSubframe2( ...
    TOW_truncated, D_star  )
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
    %       Word 6 - C_UC (16-bits), eccentricity (MSB, 9-bits)               %
    %       Word 7 - eccentricity (LSB, 24-bits)                              %
    %       Word 8 - C_US (16 bits), Root_a (MSB, 8-bits)                     %
    %       Word 9 - sqrt_a (LSB, 24-bits)                                    %
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
    %                                                                         %
    %   + by Kurt: Values for C_UC, e, C_Us, Root_a, t_oe changed to real     %
    % observed values from:                                                   %
    %   http://www.colorado.edu/geography/gcraft/notes/gps/ephclock.html      %
    %                           March 14th 2017                               %
    % ----------------------------------------------------------------------- %

    % Define Frame
    frame_id = [ 0 1 0 ];

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
        [ IDOE C_rs ];

    word_3 = GpsParityMaker( 0, word_3_no_parity, D_star );
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

    word_4 = GpsParityMaker( 0, word_4_no_parity, D_star );
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

    % Pack'em all into a 24-bit number
    word_5_no_parity = M_not_LSB ;

    word_5 = GpsParityMaker( 0, word_5_no_parity, D_star );
end

function word_6 = GenerateWord6( D_star )
% ------------------------------------------------------------------------%
% GenerateWord6() - Generates a 30 bit word containg ,C_UC (16-bits),
% eccentricity (MSB, 8-bits) and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 5
% ------------------------------------------------------------------------%

    % Define C_UC
    % C_UC is the Amplitude of the Cosine Hamronic Correction Term to the
    %   Argument of Latitude
    % C_UC is in radians, has 16-bits and a Scale Factor of 2^-29
    %       C_UC =  -3.33972E-06 =  -3.33972E-06/2^-29 = -1.7930e+03
    %       0000011100000000b
    % Note: if value is negative? Not considered in this simulation. Above
    %   number, -3.33972E-06, is represented as a positive binary.
    C_UC = [ 0 0 0 0 0 1 1 1 0 0 0 0 0 0 0 0 ];

    % Define e
    % eccentricity is Deviation from orbit
    % eccentricity has 32 bits ( 8-bits MSB in Word 6 subframe 2 )
    % eccentricity is dimensionless and has a Scale Factor of 2^-33
    % eccentricity has a range o 0.0 to 0.03
    %       e = 0.00354898 = 0.00354898/2^-33 = 3.0486e+07
    %       00000001 msb110100010010110000000010 lsb
    eccentricity_dec = 0.00354898;

    % Check range
    %   Note from the author: " I do not like that it checks the range twice.
    %        Here in word 6 and also in word 7. Need fix." -kp
    if eccentricity_dec < 0.0 || eccentricity_dec > 0.03
        error( 'Eccentricity value passed is out-of-range. Check Word 7 Subframe 2.' );
    else
        %eccentricity = [ 1 1 0 1 0 0 0 1 0 0 1 0 1 1 0 0 0 0 0 0 0 0 1 0 ]; % test
        eccentricity = str2bin_array( dec2bin( eccentricity_dec/2^-33, 32 ) ); % Returns a 32-bit binary array
        eccentricity = eccentricity(1:8); % Take 24-bit LSB only
    end

    % Pack'em all into a 24-bit number
    word_6_no_parity = [ C_UC eccentricity ];

    word_6 = GpsParityMaker(0,  word_6_no_parity, D_star );
end

function word_7 = GenerateWord7( D_star )
% ------------------------------------------------------------------------%
% GenerateWord7() - Generates a 30 bit word containg ,eccentricity ( 24 LSB )
% and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 6
% ------------------------------------------------------------------------%
    % Define e
    % eccentricity is Deviation from orbit
    % eccentricity has 32 bits ( 24-bits LSB in Word 7 subframe 2 )
    % eccentricity is dimensionless and has a Scale Factor of 2^-33
    % eccentricity has a range o 0.0 to 0.03
    %       e = 0.00354898 = 0.00354898/2^-33 = 3.0486e+07
    %       00000001 msb 110100010010110000000010 lsb
    eccentricity_dec = 0.00354898;

    % Check range
    %   Note from the author: " I do not like that it checks the range twice.
    %        Here in word 7 and also in word 6. Need fix." -kp
    if eccentricity_dec < 0.0 || eccentricity_dec > 0.03
        error( 'Eccentricity value passed is out-of-range. Check Word 7 Subframe 2.' );
    else
        %eccentricity = [ 1 1 0 1 0 0 0 1 0 0 1 0 1 1 0 0 0 0 0 0 0 0 1 0 ]; % test
        eccentricity = str2bin_array( dec2bin( eccentricity_dec/2^-33, 32 ) ); % Returns a 32-bit binary array
        eccentricity = eccentricity(9:end); % Take 24-bit LSB only
    end

    % Pack'em all into a 24-bit number
    word_7_no_parity = eccentricity;

    word_7 = GpsParityMaker( 0, word_7_no_parity, D_star );
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

    word_8 = GpsParityMaker( 0, word_8_no_parity, D_star );
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

    word_9 = GpsParityMaker( 0, word_9_no_parity, D_star );
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
        t_oe = str2bin_array( dec2bin( t_oe_dec/2^4, 16 ) );
    end

    % Define Fit Interval Flag
    % A "fit interval" flag indicates whether the ephemerides are based on a
    %   4-hour fit interval or a Greater than 4-hours.
    % Paragraph 6.2.3 defines the following operational intervals:
    %       Normal - SV normal ops: fit flag = 0 ( ref. 20.3.3.4.3.1)
    %       Short-term Extended: fit flag = 1 & IODE < 240 ( ref. 20.3.4.4 )
    %       Long-term Extended: fit flag = 1 & IODE between 240-255
    fit_interval_flag = 0; % 4-hours fit interval
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
    aodo = [ 0 0 0 0 0 ];

    % Pack'em all into a 22-bit number THIS HAS FORCE PARITY!
    word_10_no_parity = [ t_oe fit_interval_flag aodo ];

    word_10 = GpsParityMaker( 1, word_10_no_parity, D_star );
end
