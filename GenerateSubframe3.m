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
    %       Word 9 - omega_dot ( 24-bits)                                     %
    %       Word 10 - IODE (8-bits,), IDOT (14-bit)          %
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

    % Define C_rc
    %   C_rc is the Amplitude of the Cosine Harmonic Correction Term to
    %       the Orbit Radius.
    %   The equation Radius Correction:
    %       delta_r_k = C_rs sin( 2 phi_k ) + C_rc Cos ( 2 phi_k )
    %
    %   Note: C_rc and C_rs sensitivity of position is about one meter/meter
    %
    %  C_rc has a scale Factor of 2^-5. There for:
    %       5 meter = 5/(2^-5) = 160 meter
    %       160 Dec = 0000000010100000 Binary
    %
    %       321.656 meter = 321.656/(2^-5) = 1.0293e4 meter
    %       5613 Dec = 0010100000110100 Binray
    C_rc = [ 0 0 1 0 1 0 0 0 0 0 1 1 0 1 0 0 ]; % 175.406 meter
    % C_rc = [ 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0]; % 1 meter
  % Define omega
  % omega is the Argument of Perigee which is the moment in the satellite's orbit
  %   that it is closest to earth.
  % omega has 32 bits, where 8-bt MSB is in word 7 subframe 3
  % omega has a Scale Factor of 2^-31 and units of semi-circles
  % -2.56865 rad  = -0.8176 semi-circles = -0.8176/2^-31 = -1.7558e9
  % 1.7558e9 = 01101000101001110110000111000000
  % -1.7558e9 = 10010111 msb 010110001001111001000000 lsb
  omega = [ 1 0 0 1 0 1 1 1 ];
    % Define omega
    % omega is the Argument of Perigee which is the moment in the satellite's orbit
    %   that it is closest to earth.
    % omega has 32 bits, where 8-bt MSB is in word 7 subframe 3
    % omega has a Scale Factor of 2^-31 and units of semi-circles
    % -2.56865 rad  = -0.8176 semi-circles = -0.8176/2^-31 = -1.7558e9
    % 1.7558e9 = 01101000101001110110000111000000
    % -1.7558e9 = 10010111 msb 010110001001111001000000 lsb
    omega_msb = [ 1 0 0 1 0 1 1 1 ];



    % Pack'em all into a 24-bit number
    word_7_no_parity = [ C_rc omega_msb ];

    word_7 = [ word_7_no_parity ...
        GpsParityMaker( 0, word_7_no_parity, D_star ) ];
end

function word_8 = GenerateWord8( D_star )
% ------------------------------------------------------------------------%
% GenerateWord8() - Generates a 30 bit word containg ,omega (24 bits LSB)
%  and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 7
% ------------------------------------------------------------------------%

  % Define omega
  % omega is the Argument of Perigee which is the moment in the satellite's orbit
  %   that it is closest to earth.
  % omega has 32 bits, where 8-bt MSB is in word 7 subframe 3
  % omega has a Scale Factor of 2^-31 and units of semi-circles
  % -2.56865 rad  = -0.8176 semi-circles = -0.8176/2^-31 = -1.7558e9
  % 1.7558e9 = 01101000101001110110000111000000
  % -1.7558e9 = 10010111 msb 010110001001111001000000 lsb
  omega_lsb = [ 0 1 0 1 1 0 0 0 1 0 0 1 1 1 1 0 0 1 0 0 0 0 0 0 ];

    % Pack'em all into a 24-bit number
    word_8_no_parity = omega_lsb;

    word_8 = [ word_8_no_parity ...
        GpsParityMaker( 0, word_8_no_parity, D_star ) ];
end

function word_9 = GenerateWord9( D_star )
% ------------------------------------------------------------------------%
% GenerateWord9() - Generates a 30 bit word containg , omega_dot ( 24-bits)
%  and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 8
% ------------------------------------------------------------------------%
    % Define omega_dot
    % omega_dot is the Rate of Right Ascension
    % omega_dot has 24 bits
    % omega_dot is semi-circles/sec and has a Scale Factor of 2^-43
    % omega_dot has a range of -6.33E-07 to 0
    %  -8.43857E-09 rad/sec = -2.6861e-9 = -2.6861e-9/2^-43 = -2.3627e4
    % 2.3627e4 =  000000000101110001001011
    % -2.3627e4 = 111111111010001110110101

    omega_dot_dec = -2.6861e-9;

    % Check range
    if omega_dot_dec < -6.33E-07  || omega_dot_dec > 0
        error('The Rate of Right Ascension is out-of-range. Check Word 9 of Subframe 3.');
    else
        omega_dot = str2bin_array( dec2bin( omega_dot_dec/2^-43, 24 ) );
    end

    % Pack'em all into a 24-bit number
    word_9_no_parity =  omega_dot ;

    word_9 = [ word_9_no_parity ...
        GpsParityMaker( 0, word_9_no_parity, D_star ) ];
end

function word_10 = GenerateWord10( D_star )
% ------------------------------------------------------------------------%
% GenerateWord10() - Generates a 30 bit word containg IODE (8-bits),
%  IDOT (14-bit)  and Parity bits.
%
%   Inputs:     D_star - Bits 29 and 30 of word 9
% ------------------------------------------------------------------------%

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
  %   For Simulation IDOC = 157 = 0010011101b
  % IDOE is the LSB 8-bits of IODC
  IDOE = [ 1 0 0 1 1 1 0 1 ];

  % Define IDOT
  % IDOT is the Rate of Inclination Angle
  % IDOT has 14-bits and a Scale Factor of 2^-43. Units of semi-circles/sec
  % The Corrected Inclination equation:
  %   i_k = i_not + delta_i_k + IDOT*t_k
  %       Found on Table 20-IV
  % IDOT = 4.11089E-10 rad/sec = 1.3085e-10 semi-circles/sec
  % =  1.3085e-10/2^-43 = 1.1510e3 = 00010001111111 b
  IDOT = [ 0 0 0 1 0 0 0 1 1 1 1 1 1 1 ];

    % Pack'em all into a 22-bit number THIS HAS FORCE PARITY!
    word_10_no_parity = [ IDOE IDOT ];

    word_10 = [ word_10_no_parity ...
        GpsParityMaker( 1, word_10_no_parity, D_star ) ];
end
