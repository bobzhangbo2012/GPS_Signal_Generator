function subframe_4_300_bits = GenerateSubframe4(...
  page_number, TOW_truncated, GPS_week_number, sv_t_ot, full_sv_health_data,...
  full_almanac_data, D_star )
% ----------------------------------------------------------------------- %
%  GenerateSubframe4 - Generates the second subframe of a GPS Message. It %
%   contains 300 bits, 10 words each 30 bits. The following define each   %
%   bit content:                                                          %
%                                                                         %
%       Pages 1, 6, 11, 16 and 21 - Reserved                              %
%       Pages 12, 19, 20, 22, 23, and 24 - Reserved                       %
%       Pages 2, 3, 4, 5, 7, 8, 9 and 10 - Almanac data for SV 25 to 32   %
%       Page 13 - NMCT ( Navigation Message Correction Table )            %
%       Page 14 and 15 - Reserved for system use                          %
%       Page 17 - Special Messages                                        %
%       Page 18 - Ionosheric and UTC data                                 %
%       Page 25 - A-S flag SV configurations for 32 SVs, plus SV health   %
%                 for SV 25 through 32                                    %
%                                                                         %
% ----------------------------------------------------------------------- %
%               Created by Kurt Pedrosa  -- March 03th 2017               %
% ----------------------------------------------------------------------- %
% Using a polynomial function determin the SV given the page number

    % Insure page number is between 1-25
    if page_number < 0 || page_number > 25
        error('Incorrect page number in Subframe 4.');
    end

    % Define Frame
    frame_id = [ 1 0 0 ];

    % Define all 300 bits, all 10 words for given page
    word_1  = GenerateTLMWord( D_star );
    word_2  = GenerateHOWWord( TOW_truncated, frame_id, word_1( 29:30 ));
    word_3 = GenerateWord3( page_number, full_almanac_data, word_2( 29:30 ) );
    word_4 = GenerateWord4( page_number, full_almanac_data, word_3( 29:30 ) );
    word_5 = GenerateWord5( page_number, full_almanac_data, word_4( 29:30 ) );
    word_6 = GenerateWord6( page_number, full_almanac_data, word_5( 29:30 ) );
    word_7 = GenerateWord7( page_number, word_6( 29:30 ) );
    word_8 = GenerateWord8( page_number, sv_t_ot, GPS_week_number, full_sv_health_data( 25 ),...
                full_almanac_data, word_2( 29:30 ) );
    word_9 = GenerateWord9( page_number, GPS_week_number, full_sv_health_data( 26:29 ),...
                full_almanac_data, word_2( 29:30 ) );
    word_10 = GenerateWord10( page_number,full_sv_health_data( 30:32 ),...
                full_almanac_data, word_2( 29:30 ) );

    % Returns a array of 10 x 30 bits
    %   Each row is a word. For example
    %      + To access word 8 - subframe_1_300_bits( 8, : )
    %      + To access word 10 bit 29 and 30  - subframe_1_300_bits( 10, (29:30) );
    subframe_4_300_bits = [ word_1 ;
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

function word_3 = GenerateWord3( page_number, full_almanac_data, D_star )
    % --------------------------------------------------------------------------- %
    % GenerateWord3() - Generates a 30 bit word data depending on page number,    %
    %       including parity bits.                                                %
    % --------------------------------------------------------------------------- %
    if any( page_number == [ 2, 3, 4, 5, 7, 8, 9, 10 ] )
      % Polynomial equation that returns a SV index number between 25 and 32
      % for example : Page 2 - sv_indexed= 25
      % This is due to the fact that pages 2, 3, 4, 5, 7, 8, 9, 10 are
      %   ephemeris data for SV 25 thru 32
      sv_indexed =  round( ( -1787/181440 ) * page_number^9 + ...
                    ( 2161/4480 ) * page_number^8 - ...
                    ( 152611/15120 ) *  page_number^7 + ...
                    ( 339491/2880 ) * page_number^6 - ...
                    ( 1455307/1728 ) * page_number^5 + ...
                    ( 21846103/5760 ) * page_number^4 - ...
                    ( 969047939/90720 ) * page_number^3 + ...
                    ( 181025839/10080 ) * page_number^2 - ...
                    ( 40634899/2520 ) * page_number + ...
                    5789 );

      % Define Data_id
      %   For NAV data data_id must be [ 0 1 ] (2)
      data_id = [ 0 1 ];
      % Define SV_id
      sv_health = full_almanac_data( sv_indexed, 2 );

      % Catch for dummy SV
      if sv_health == 63
          sv_id = str2bin_array( dec2bin( 0, 6 ) );
      else
          sv_id = str2bin_array( dec2bin( sv_indexed, 6 ) );
      end

      % Define eccentricity
      % Check range
      sv_eccentricity = full_almanac_data( sv_indexed, 3 );

      if (sv_eccentricity < 0.0 || sv_eccentricity > 0.03) && sv_eccentricity ~= 0.0208330154418945
          eccentricity = dec2bin( 0, 16 );
          error( 'Eccentricity value passed is out-of-range. Check Word 3 Subframe 4.' );
      else
          %eccentricity = [ 1 1 0 1 0 0 0 1 0 0 1 0 1 1 0 0 0 0 0 0 0 0 1 0 ]; % test
          eccentricity = SvData2Binary( sv_eccentricity/2^-21, 16);
      end

      % Pack'em all into a 24-bit number
      word_3_no_parity = [ data_id sv_id eccentricity ];

    elseif any( page_number == [ 1, 6, 11, 16, 21, 12, 19, 20, 22, 23, 24 ] )
        % Define Data ID (2 bits)
        data_id = [ 0 1 ];
        % Define Sv ID (6 bits)
        if any( page_number == [ 1, 6, 11, 16, 21 ] )
            sv_id = str2bin_array( dec2bin( 57, 6 ));
        elseif any( page_number ==  [ 12, 24 ] )
            sv_id = str2bin_array( dec2bin( 62, 6 ));
        elseif page_number == 19
            % Note (3) - SV ID may cary (expet for IIR/IIR-M/IIF/GPS III SVs)
            sv_id = str2bin_array( dec2bin( 58, 6 ));
        elseif page_number == 20
            % Note (3) - SV ID may cary (expet for IIR/IIR-M/IIF/GPS III SVs)
            sv_id = str2bin_array( dec2bin( 59, 6 ));
        elseif page_number == 22
            % Note (3) - SV ID may cary (expet for IIR/IIR-M/IIF/GPS III SVs)
            sv_id = str2bin_array( dec2bin( 60, 6 ));
        elseif page_number == 23
            % Note (3) - SV ID may cary (expet for IIR/IIR-M/IIF/GPS III SVs)
            sv_id = str2bin_array( dec2bin( 61, 6 ));
        else
            error('Page number error. Check SV ID word 3 Subframe 4 Page %d.', page_number );
        end
        % Define reserved bits (16 bits)
        reserved = [ 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ];

        % Pack'em all into a 24-bit number
        word_3_no_parity = [ data_id sv_id reserved ];

    elseif page_number == 18
        % Define Data id
        data_id = [ 0 1 ];
        % Define sv_id
        sv_id = str2bin_array( dec2bin( 56, 6 ));
        % Ionospheric correction terms
        % Ionospheric paramenters allow users to utilized the model
        %   to computer the ionospheric delay.
        % Ionospheric model shown in Figuer 20-4
        % Single frequency users will decrese RMS error if delay calulated
        alpha_not = [ 0 0 0 0 0 0 0 0 ]; % 8 bits
        alpha_one = [ 0 0 0 0 0 0 0 0 ]; % 8 bits

        % Pack'em all into a 24-bit number
        word_3_no_parity = [ data_id sv_id alpha_not alpha_one ];

    elseif page_number == 25
        % Define Data id
        data_id = [ 0 1 ];
        % Define sv_id
        sv_id = str2bin_array( dec2bin( 63, 6 ));
        % Anti-Spoof Flags and SV configurations
        % 4-bit number MSB 1 = A-Spoof is ON
        %   LSB (3-bit) SV config:
        %       000 Reserved
        %       001 A-S capability, plus flags for A-S and "alart" in HOW
        %       010 A-S capability, plus flags for A-S and "alart" in HOW
        %           M-Code capability, L2C signal capability
        %       011 A-S capability, plus flags for A-S and "alart" in HOW
        %            M-Code capability, L2C signal capability, L5 signal capability
        %       100 A-S capability, plus flags for A-S and "alart" in HOW
        %            M-Code capability, L2C signal capability, L5 signal capability
        %           L1C signal capability, no SA capability
        %       101, 110, 111 Reserved
        a_spoof_sv1 = [ 1 0 0 1 ];
        a_spoof_sv2 = [ 1 0 0 1 ];
        a_spoof_sv3 = [ 1 0 0 1 ];
        a_spoof_sv4 = [ 1 0 0 1 ];

        % Pack'em all into a 24-bit number
        word_3_no_parity =...
        [ data_id sv_id a_spoof_sv1 a_spoof_sv2 a_spoof_sv3 a_spoof_sv4 ];

    elseif page_number == 13
        % Define Data id
        data_id = [ 0 1 ];
        % Define sv_id
        sv_id = str2bin_array( dec2bin( 52, 6 ));
        % Define availability indicator
        % 00 - Unencrypted and is available to all'
        % 01 - Encrypted and available only to authorized users (NORMAL MODE)
        % 10 - No data available
        % 11 -  Reserved
        avail_indicator = [ 0 1 ];

        % Define ERDs
        %   Normal mode these are encrypted. C/A has not access therefor
        %       they will be set to 0's
        % In the case that ERD is not valid for a sv the value 100000 is passed
        erd1 = [ 0 0 0 0 0 0 ];
        erd2 = [ 0 0 0 0 0 0 ];
        erd3 = [ 0 0 ]; % Other 4 bits in Word 4

        % Pack'em all into a 24-bit number
        word_3_no_parity =[ data_id sv_id avail_indicator erd1 erd2 erd3 ];

    elseif any( page_number == [ 14, 15, 17 ] )
        % Define Data id
        data_id = [ 0 1 ];
        % Define sv_id
        if page_number == 14
            % Define sv_id
            sv_id = str2bin_array( dec2bin( 53, 6 ));
        elseif page_number == 15
            % Define sv_id
            sv_id = str2bin_array( dec2bin( 54, 6 ));
        elseif page_number == 17
            % Define sv_id
            sv_id = str2bin_array( dec2bin( 55, 6 ));
        else
            error('Invalid page number. Check Word 3 Subframe 4 Page %d', page_number );
        end

        % Define remaining bits depending on page
        %   Pages 14 and 15 use bits as Reserved for System use
        %   Page 17 use bits as special messager per Paragraph 20.3.3.5.1.8
        if page_number == 17
            % Special Message 16 bits
            % For testing, "[TH]IS IS A TEST" will be sent.
            % T = 84 dec = 01 010 100 bin = 124 octal
            % H = 72 dec = 01 001 000 bin = 110 octal
            special_msg_char = [ 0 1 0 1 0 1 0 0 0 1 0 0 1 0 0 0 ];

            % Pack'em all into a 24-bit number
            word_3_no_parity =[ data_id sv_id special_msg_char ];
        else
            % Reserved for system use (16 bits)
            reserved = [ 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ];

            % Pack'em all into a 24-bit number
            word_3_no_parity =[ data_id sv_id reserved ];
        end
    end

    word_3 = GpsParityMaker( 0, word_3_no_parity, D_star );
end

function word_4 = GenerateWord4( page_number, full_almanac_data, D_star )
    % --------------------------------------------------------------------------- %
    % GenerateWord4() - Generates a 30 bit word data depending on page number,    %
    %       including parity bits.                                                %
    % --------------------------------------------------------------------------- %
    if any( page_number == [ 2, 3, 4, 5, 7, 8, 9, 10 ] );
      % Polynomial equation that returns a SV index number between 25 and 32
      % for example : Page 2 - sv_indexed= 25
      % This is due to the fact that pages 2, 3, 4, 5, 7, 8, 9, 10 are
      %   ephemeris data for SV 25 thru 32
      sv_indexed =  round( ( -1787/181440 ) * page_number^9 + ...
                    ( 2161/4480 ) * page_number^8 - ...
                    ( 152611/15120 ) *  page_number^7 + ...
                    ( 339491/2880 ) * page_number^6 - ...
                    ( 1455307/1728 ) * page_number^5 + ...
                    ( 21846103/5760 ) * page_number^4 - ...
                    ( 969047939/90720 ) * page_number^3 + ...
                    ( 181025839/10080 ) * page_number^2 - ...
                    ( 40634899/2520 ) * page_number + ...
                    5789 );
      % Define t_oa (8 bits)
      sv_t_oa = full_almanac_data( sv_indexed, 4 );
      % Check range
      if  sv_t_oa > 602112 || sv_t_oa < 0
          t_oa = dec2bin( 0, 8 );
          error('The Time of Applicabitity is out-of-range. Check Word 4 of Subframe 4.');
      else
          t_oa = SvData2Binary( sv_t_oa/ 2^12, 8 );
      end
      % Define delta_i ( 16 bits )
      % Nominal inclination angle of 0.20 semicircles is implicit
      % delat_i is the correction to inclination.
      % Not passed by the Yuma data. Setting it to zeros
      delta_i = [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];

      % Pack'em all into a 24-bit number
      word_4_no_parity = [ t_oa delta_i ];

    elseif any( page_number == [ 1, 6, 11, 16, 21, 12, 19, 20, 22, 23, 24 ] )
        reserved = GenerateReservedWord();

        % Pack'em all into a 24-bit number
        word_4_no_parity = reserved;

    elseif page_number == 18
        % Ionospheric correction terms
        % Ionospheric paramenters allow users to utilized the model
        %   to computer the ionospheric delay.
        % Ionospheric model shown in Figuer 20-4
        % Single frequency users will decrese RMS error if delay calulated
        alpha_two = [ 0 0 0 0 0 0 0 0 ]; % 8 bits
        alpha_three = [ 0 0 0 0 0 0 0 0 ]; % 8 bits
        beta_not = [ 0 0 0 0 0 0 0 0 ];  % 8 bits

        % Pack'em all into a 24-bit number
        word_4_no_parity = [ alpha_two alpha_three beta_not ];

    elseif page_number == 25
        anti_spoof_6_sv = GenerateAntiSpoofWord();

        % Pack'em all into a 24-bit number
        word_4_no_parity = anti_spoof_6_sv;

    elseif page_number == 13
        erd_5_sv = GenerateERDWord();

        % Pack'em all into a 24-bit number
        word_4_no_parity = erd_5_sv;

    elseif any( page_number == [ 14, 15, 17, ] )
        if page_number == 17
            % Special Message 16 bits
            % For testing, "TH[IS ]IS A TEST" will be sent.
            % I = 01 001 001 bin = 111 octal
            % S = 01 010 011 bin = 123 octal
            % space = 040 ocatl = 00 100 00
            special_msg_char = [ 0 1 0 0 1 0 0 1 0 1 0 1 0 0 1 1 0 0 1 0 0 0 0 0 ];

            % Pack'em all into a 24-bit number
            word_4_no_parity = special_msg_char;

        else
            % Reserved for system use (16 bits)
            reserved = GenerateReservedWord();

            % Pack'em all into a 24-bit number
            word_4_no_parity = reserved;
        end
    end

    word_4 = GpsParityMaker( 0, word_4_no_parity, D_star );
end

function word_5 = GenerateWord5( page_number, full_almanac_data, D_star )
    % --------------------------------------------------------------------------- %
    % GenerateWord5() - Generates a 30 bit word data depending on page number,    %
    %       including parity bits.                                                %
    % --------------------------------------------------------------------------- %
    if any( page_number == [ 2, 3, 4, 5, 7, 8, 9, 10 ] );
      % Polynomial equation that returns a SV index number between 25 and 32
      % for example : Page 2 - sv_indexed= 25
      % This is due to the fact that pages 2, 3, 4, 5, 7, 8, 9, 10 are
      %   ephemeris data for SV 25 thru 32
      sv_indexed =  round( ( -1787/181440 ) * page_number^9 + ...
                    ( 2161/4480 ) * page_number^8 - ...
                    ( 152611/15120 ) *  page_number^7 + ...
                    ( 339491/2880 ) * page_number^6 - ...
                    ( 1455307/1728 ) * page_number^5 + ...
                    ( 21846103/5760 ) * page_number^4 - ...
                    ( 969047939/90720 ) * page_number^3 + ...
                    ( 181025839/10080 ) * page_number^2 - ...
                    ( 40634899/2520 ) * page_number + ...
                    5789 );
      % Define omega_dot (16-bits)
      omega_dot_dec = full_almanac_data( sv_indexed, 6 )/pi;

      % Check range
      if ( omega_dot_dec < -6.33E-07  || omega_dot_dec > 0 ) && omega_dot_dec*pi ~= 4.99335085024861e-07
        omega_dot = bin2dec( 0, 24 );
        error('The Rate of Right Ascension is out-of-range. Check Word 5 of Subframe 4');
      else
        omega_dot = SvData2Binary( omega_dot_dec/ 2^-38, 16 );
      end
      % Define SV Health
      health = SvData2Binary( full_almanac_data( sv_indexed, 2), 8 );

      % Pack'em all into a 24-bit number
      word_5_no_parity = [ omega_dot health ];

    elseif any( page_number == [ 1, 6, 11, 16, 21, 12, 19, 20, 22, 23, 24 ] )
        reserved = GenerateReservedWord();

        % Pack'em all into a 24-bit number
        word_5_no_parity = reserved;

    elseif page_number == 18
        % Ionospheric correction terms
        % Ionospheric paramenters allow users to utilized the model
        %   to computer the ionospheric delay.
        % Ionospheric model shown in Figuer 20-4
        % Single frequency users will decrese RMS error if delay calulated
        beta_one = [ 0 0 0 0 0 0 0 0 ]; % 8 bits
        beta_two = [ 0 0 0 0 0 0 0 0 ]; % 8 bits
        beta_three = [ 0 0 0 0 0 0 0 0 ];  % 8 bits

        % Pack'em all into a 24-bit number
        word_5_no_parity = [ beta_one beta_two beta_three ];

    elseif page_number == 25
        anti_spoof_6_sv = GenerateAntiSpoofWord();

        % Pack'em all into a 24-bit number
        word_5_no_parity = anti_spoof_6_sv;

    elseif page_number == 13
        erd_5_sv = GenerateERDWord();

        % Pack'em all into a 24-bit number
        word_5_no_parity = erd_5_sv;

elseif any( page_number == [ 14, 15, 17 ] )
        if page_number == 17
            % Special Message 16 bits
            % For testing, "THIS [IS ]A TEST" will be sent.
            % I = 01 001 001 bin = 111 octal
            % S = 01 010 011 bin = 123 octal
            % space = 040 ocatl = 00 100 00
            special_msg_char = [ 0 1 0 0 1 0 0 1 0 1 0 1 0 0 1 1 0 0 1 0 0 0 0 0 ];

            % Pack'em all into a 24-bit number
            word_5_no_parity = special_msg_char;

        else
            % Reserved for system use (16 bits)
            reserved = GenerateReservedWord();

            % Pack'em all into a 24-bit number
            word_5_no_parity = reserved;
        end
    end

    word_5 = GpsParityMaker( 0, word_5_no_parity, D_star );
end

function word_6 = GenerateWord6( page_number, full_almanac_data, D_star )
    % --------------------------------------------------------------------------- %
    % GenerateWord6() - Generates a 30 bit word data dependisv_sqrt_ang on page number,    %
    %       including parity bits.                                                %
    % --------------------------------------------------------------------------- %
    if any( page_number == [ 2, 3, 4, 5, 7, 8, 9, 10 ] );
      % Polynomial equation that returns a SV index number between 25 and 32
      % for example : Page 2 - sv_indexed= 25
      % This is due to the fact that pages 2, 3, 4, 5, 7, 8, 9, 10 are
      %   ephemeris data for SV 25 thru 32
      sv_indexed =  round( ( -1787/181440 ) * page_number^9 + ...
                    ( 2161/4480 ) * page_number^8 - ...
                    ( 152611/15120 ) *  page_number^7 + ...
                    ( 339491/2880 ) * page_number^6 - ...
                    ( 1455307/1728 ) * page_number^5 + ...
                    ( 21846103/5760 ) * page_number^4 - ...
                    ( 969047939/90720 ) * page_number^3 + ...
                    ( 181025839/10080 ) * page_number^2 - ...
                    ( 40634899/2520 ) * page_number + ...
                    5789 );
      % Define sqrt_a ( 24 bits )
      % Check range
      sqrt_a_dec = full_almanac_data( sv_indexed, 7 );

      if sqrt_a_dec < 2530 || sqrt_a_dec > 8192
          sqrt_a = bin2dec( 0, 24 );
          error('Squre Root of the Semi-Major Axis is out-of-range. Check Word 8 of Subframe 4.');
      else
          sqrt_a = SvData2Binary( sqrt_a_dec/2^-11, 24 );
      end

      % Pack'em all into a 24-bit number
      word_6_no_parity = sqrt_a;

    elseif any( page_number == [ 1, 6, 11, 16, 21, 12, 19, 20, 22, 23, 24 ] )
        reserved = GenerateReservedWord();

        % Pack'em all into a 24-bit number
        word_6_no_parity = reserved;

    elseif page_number == 18
        % Define A1
        % Drift coefficient of GPS time scale relative to UTC time Scale
        A_1 = [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];

         % Pack'em all into a 24-bit number
        word_6_no_parity = A_1;
        
    elseif page_number == 13
        erd_5_sv = GenerateERDWord();

        % Pack'em all into a 24-bit number
        word_6_no_parity = erd_5_sv;

    elseif page_number == 25
        anti_spoof_6_sv = GenerateAntiSpoofWord();

        % Pack'em all into a 24-bit number
        word_6_no_parity = anti_spoof_6_sv;

    elseif page_number == 13
        erd_5_sv = GenerateERDWord();

        % Pack'em all into a 24-bit number
        word_6_no_parity = erd_5_sv;

    elseif any( page_number == [ 14, 15, 17 ] )
        if page_number == 17
            % Special Message 16 bits
            % For testing, "THIS IS [A T]EST" will be sent.
            % A = 01 000 001 bin = 101 octal
            % space = 040 ocatl = 00 100 000
            % T = 84 dec = 01 010 100 bin = 124 octal
            special_msg_char = [ 0 1 0 0 0 0 0 1 0 0 1 0 0 0 0 0 0 1 0 1 0 1 0 0 ];

            % Pack'em all into a 24-bit number
            word_6_no_parity = special_msg_char;

        else
            % Reserved for system use (16 bits)
            reserved = GenerateReservedWord();

            % Pack'em all into a 24-bit number
            word_6_no_parity = reserved;
        end
    end

    word_6 = GpsParityMaker( 0, word_6_no_parity, D_star );
end

function word_7 = GenerateWord7( page_number, D_star )
    % --------------------------------------------------------------------------- %
    % GenerateWord7() - Generates a 30 bit word data depending on page number,    %
    %       including parity bits.                                                %
    % --------------------------------------------------------------------------- %
    if any( page_number == [ 2, 3, 4, 5, 7, 8, 9, 10 ] );
      % Define omega_not
      % omega_not is the Longitude of Ascending Node of Orbit Plane at Weekly Epoch
      % omega_not is 24-bit
      % omega_not has a Scale Factor of 2^-31 and measured in semi-circles
      % Note: No observed date was found online. Value of zero chosen for simulation
      %   omega_not = 0 = 0/2^-23 = 0 = 00000000 MSB 000000000000000000000000b
      omega_not = [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];

      word_7_no_parity = omega_not;

    elseif any( page_number == [ 1, 6, 11, 16, 21, 12, 19, 20, 22, 23, 24 ] )
        reserved = GenerateReservedWord();

        % Pack'em all into a 24-bit number
        word_7_no_parity = reserved;

    elseif page_number == 18
        % Define A0
        % Semi-Major Axis at reference time
        % 24 bit MSB
        A_not = [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];

        % Pack'em all into a 24-bit number
        word_7_no_parity = A_not;

    elseif page_number == 25
        anti_spoof_6_sv = GenerateAntiSpoofWord();

        % Pack'em all into a 24-bit number
        word_7_no_parity = anti_spoof_6_sv;

    elseif page_number == 13
        erd_5_sv = GenerateERDWord();

        % Pack'em all into a 24-bit number
        word_7_no_parity = erd_5_sv;

    elseif any( page_number == [ 14, 15, 17 ] )
        if page_number == 17
            % Special Message 16 bits
            % For testing, "THIS IS A T[EST]" will be sent.
            % E = 01 000 101 bin = 105 octal
            % S = 01 010 011 = 123 octal
            % T = 84 dec = 01 010 100 bin = 124 octal
            special_msg_char = [ 0 1 0 0 0 1 0 1 0 1 0 1 0 0 1 1 0 1 0 1 0 1 0 0 ];

            % Pack'em all into a 24-bit number
            word_7_no_parity = special_msg_char;

        else
            % Reserved for system use (16 bits)
            reserved = GenerateReservedWord();

            % Pack'em all into a 24-bit number
            word_7_no_parity = reserved;
        end
    end

    word_7 = GpsParityMaker( 0, word_7_no_parity, D_star );
end

function word_8 = GenerateWord8(...
    page_number, sv_t_ot, GPS_week_number, full_sv_health_data, full_almanac_data, D_star )
    % --------------------------------------------------------------------------- %
    % GenerateWord8() - Generates a 30 bit word data depending on page number,    %
    %       including parity bits.                                                %
    % --------------------------------------------------------------------------- %
    if any( page_number == [ 2, 3, 4, 5, 7, 8, 9, 10 ] );
      % Polynomial equation that returns a SV index number between 25 and 32
      % for example : Page 2 - sv_indexed= 25
      % This is due to the fact that pages 2, 3, 4, 5, 7, 8, 9, 10 are
      %   ephemeris data for SV 25 thru 32
      sv_indexed =  round( ( -1787/181440 ) * page_number^9 + ...
                    ( 2161/4480 ) * page_number^8 - ...
                    ( 152611/15120 ) *  page_number^7 + ...
                    ( 339491/2880 ) * page_number^6 - ...
                    ( 1455307/1728 ) * page_number^5 + ...
                    ( 21846103/5760 ) * page_number^4 - ...
                    ( 969047939/90720 ) * page_number^3 + ...
                    ( 181025839/10080 ) * page_number^2 - ...
                    ( 40634899/2520 ) * page_number + ...
                    5789 );
      omega = SvData2Binary(( ...
        full_almanac_data( sv_indexed, 9 )/pi)/2^-23, 24 );

      word_8_no_parity = omega;

    elseif any( page_number == [ 1, 6, 11, 16, 21, 12, 19, 20, 22, 23, 24 ] )
        reserved = GenerateReservedWord();

        % Pack'em all into a 24-bit number
        word_8_no_parity = reserved;

    elseif page_number == 18
        % Define A0
        % Semi-Major Axis at reference time
        % 8 bit LSB
        A_not = [ 0 0 0 0 0 0 0 0 ];
        % Define t_ot - reference time for UTC data
        % Range 0 to 602112
        % Scale factor 2^12
        if  sv_t_ot > 602112 || sv_t_ot < 0
            t_ot = dec2bin( 0, 8 );
            error('The Semi-Major Axis at Reference Time is out-of-range. Check Word  of Subframe 4 Page %d.', page_number );
        else
            t_ot = SvData2Binary( sv_t_ot/ 2^12, 8 );
        end
        % Define WN_t - UTC reference week number
        WN_t = str2bin_array( dec2bin( mod( GPS_week_number, 256 ), 8 ));

        % Pack'em all into a 24-bit number
        word_8_no_parity = [ A_not t_ot WN_t ];

    elseif page_number == 25
        anti_spoof_sv29 = [ 1 0 0 1 ];
        anti_spoof_sv30 = [ 1 0 0 1 ];
        anti_spoof_sv31 = [ 1 0 0 1 ];
        anti_spoof_sv32 = [ 1 0 0 1 ];

        reserved_2_bits = [ 1 0 ];

        sv_25_health = str2bin_array( dec2bin( full_sv_health_data, 6 ));

        % Pack'em all into a 24-bit number
        word_8_no_parity =...
         [ anti_spoof_sv29 anti_spoof_sv30 anti_spoof_sv31 anti_spoof_sv32 reserved_2_bits sv_25_health ];

    elseif page_number == 13
        erd_5_sv = GenerateERDWord();

        % Pack'em all into a 24-bit number
        word_8_no_parity = erd_5_sv;

    elseif any( page_number == [ 14, 15, 17 ] )
        if page_number == 17
            % Special Message 16 bits
            % For testing, "THIS IS A TEST" will be sent.
            % space = 040 ocatl = 00 100 000 x 3
            special_msg_char = [ 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 ];

            % Pack'em all into a 24-bit number
            word_8_no_parity = special_msg_char;

        else
            % Reserved for system use (16 bits)
            reserved = GenerateReservedWord();

            % Pack'em all into a 24-bit number
            word_8_no_parity = reserved;
        end
    end

    word_8 = GpsParityMaker( 0, word_8_no_parity, D_star );
end

function word_9 = GenerateWord9(...
    page_number, GPS_week_number, full_sv_health_data, full_almanac_data, D_star )
    % --------------------------------------------------------------------------- %
    % GenerateWord9() - Generates a 30 bit word data depending on page number,    %
    %       including parity bits.                                                %
    % --------------------------------------------------------------------------- %
    if any( page_number == [ 2, 3, 4, 5, 7, 8, 9, 10 ] );
      % Polynomial equation that returns a SV index number between 25 and 32
      % for example : Page 2 - sv_indexed= 25
      % This is due to the fact that pages 2, 3, 4, 5, 7, 8, 9, 10 are
      %   ephemeris data for SV 25 thru 32
      sv_indexed =  round( ( -1787/181440 ) * page_number^9 + ...
                    ( 2161/4480 ) * page_number^8 - ...
                    ( 152611/15120 ) *  page_number^7 + ...
                    ( 339491/2880 ) * page_number^6 - ...
                    ( 1455307/1728 ) * page_number^5 + ...
                    ( 21846103/5760 ) * page_number^4 - ...
                    ( 969047939/90720 ) * page_number^3 + ...
                    ( 181025839/10080 ) * page_number^2 - ...
                    ( 40634899/2520 ) * page_number + ...
                    5789 );
      % Define M_not
      %   M_not is the Mean Anomaly at Reference Time
      %   M_not has 32 bits ( 8-bits in word 4 of Subframe 2 )
      %   M_not has a Scale Factor of 2^-31
      %   M_not = 0 semi-circles = 0/(2^-31) = 0 semi-circles
      %   M_not = 1.41596 rad = 0.4507140664408 semi-circles ...
      %       = 0.4507140664408/(2^-31) = 9.6790 e8
      %       = 00111001 101100001111111110011111 binary
      %   Note: 1 sem-circle = 3.1415926535 radians
      M_not =  SvData2Binary((...
       full_almanac_data( sv_indexed, 10 )/pi )/( 2^-23 ), 24 );

      word_9_no_parity = M_not;

    elseif any( page_number == [ 1, 6, 11, 16, 21, 12, 19, 20, 22, 23, 24 ] )
        reserved_8_bits = [ 1 0 1 0 1 0 1 0 ];
        reserved_16_bits = [ 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ];

        % Pack'em all into a 24-bit number
        word_9_no_parity = [ reserved_8_bits reserved_16_bits ];

    elseif page_number == 18
        % Define delta_t_LS
        %   delay delta due to leap seconds
        % 8 bits, scale 1.
        delta_t_LS = [ 0 0 0 0 0 0 0 0 ];

        % Define WN_LSF
        % Time data reference Week Number
        % when delta_t_LS and delta_t_LSF differ, the absolute value of the
        %   differnece between the untruncated WN and WN_LSF values shall not
        %   exceed 127.
        % For me check out 20.3.3.5.2.4
        WN_LSF = str2bin_array( dec2bin( mod( GPS_week_number, 256 ), 8 ));

        % Define DN
        % Day number is an 8 bit number. "Day one" is the first day relative
        %   to the end/start of week and WN_LSF value consist of 8 bits which
        %   shall be a modulo 256 bin representation of the GPS week number
        %   to wich the DN is referenced. Paragraph 20.3.3.5.2.4
        % Range 1 - 7  Day
        DN_dec = weekday( now ); % ook at date string
        DN = str2bin_array( dec2bin( DN_dec, 8 ) );


        % Pack'em all into a 24-bit number
        word_9_no_parity = [ delta_t_LS WN_LSF DN ];

    elseif page_number == 25

        sv_26_health = str2bin_array( dec2bin( full_sv_health_data( 1 ), 6 ));
        sv_27_health = str2bin_array( dec2bin( full_sv_health_data( 2 ), 6 ));
        sv_28_health = str2bin_array( dec2bin( full_sv_health_data( 3 ), 6 ));
        sv_29_health = str2bin_array( dec2bin( full_sv_health_data( 4 ), 6 ));

        % Pack'em all into a 24-bit number
        word_9_no_parity = [ sv_26_health sv_27_health sv_28_health sv_29_health ];

    elseif page_number == 13
        erd_5_sv = GenerateERDWord();

        % Pack'em all into a 24-bit number
        word_9_no_parity = erd_5_sv;

    elseif any( page_number == [ 14, 15, 17 ] )
        if page_number == 17
            % Special Message 16 bits
            % For testing, "THIS IS A TEST" will be sent.
            % space = 040 ocatl = 00 100 000 x 3
            special_msg_char = [ 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 ];

            % Pack'em all into a 24-bit number
            word_9_no_parity = special_msg_char;

        else
            % Reserved for system use (16 bits)
            reserved = GenerateReservedWord();

            % Pack'em all into a 24-bit number
            word_9_no_parity = reserved;
        end
    end

    word_9 = GpsParityMaker( 0, word_9_no_parity, D_star );
end

function word_10 = GenerateWord10(...
    page_number, full_sv_health_data, full_almanac_data, D_star )
    % --------------------------------------------------------------------------- %
    % GenerateWord9() - Generates a 30 bit word data depending on page number,    %
    %       including parity bits.                                                %
    % --------------------------------------------------------------------------- %
    if any( page_number == [ 2, 3, 4, 5, 7, 8, 9, 10 ] );
      % Polynomial equation that returns a SV index number between 25 and 32
      % for example : Page 2 - sv_indexed= 25
      % This is due to the fact that pages 2, 3, 4, 5, 7, 8, 9, 10 are
      %   ephemeris data for SV 25 thru 32
      sv_indexed =  round( ( -1787/181440 ) * page_number^9 + ...
                    ( 2161/4480 ) * page_number^8 - ...
                    ( 152611/15120 ) *  page_number^7 + ...
                    ( 339491/2880 ) * page_number^6 - ...
                    ( 1455307/1728 ) * page_number^5 + ...
                    ( 21846103/5760 ) * page_number^4 - ...
                    ( 969047939/90720 ) * page_number^3 + ...
                    ( 181025839/10080 ) * page_number^2 - ...
                    ( 40634899/2520 ) * page_number + ...
                    5789 );

      a_f0 = SvData2Binary( full_almanac_data( sv_indexed, 11 )/( 2^-20 ), 11);
      a_f1 = SvData2Binary( full_almanac_data( sv_indexed, 12 )/( 2^-38 ), 11);

      word_10_no_parity = [ a_f0(1:8) a_f1 a_f0(9:11) ];

    elseif any( page_number == [ 1, 6, 11, 16, 21, 12, 19, 20, 22, 23, 24 ] )
        reserved = [ 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ]; % 22 bits

        % Pack'em all into a 24-bit number
        word_10_no_parity = reserved;

    elseif page_number == 18
        % Define delta_t_LSF
        %   delay delta due to leap seconds
        % 8 bits, scale 1.
        delta_t_LSF = [ 0 0 0 0 0 0 0 0 ];

        reserved_system_use = [ 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ];

        % Pack'em all into a 24-bit number
        word_10_no_parity = [ delta_t_LSF reserved_system_use ];

    elseif page_number == 25

        sv_30_health = str2bin_array( dec2bin( full_sv_health_data( 1 ), 6 ));
        sv_31_health = str2bin_array( dec2bin( full_sv_health_data( 2 ), 6 ));
        sv_32_health = str2bin_array( dec2bin( full_sv_health_data( 3 ), 6 ));

        reserved_system_use = [ 1 0 1 0 ];

        % Pack'em all into a 24-bit number
        word_10_no_parity = [ sv_30_health  sv_31_health sv_32_health reserved_system_use ];

    elseif page_number == 13
        % Only the 22 bit MSB
        erd_5_sv = GenerateERDWord();

        % Pack'em all into a 24-bit number
        word_10_no_parity = erd_5_sv( 1:22 );

    elseif any( page_number == [ 14, 15, 17 ] )
            reserved_system_use = [ 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ];

            % Pack'em all into a 24-bit number
            word_10_no_parity = reserved_system_use;
    end

    word_10 = GpsParityMaker( 1, word_10_no_parity, D_star );
end

function reserved_word = GenerateReservedWord()
    % --------------------------------------------------------------------------- %
    % GenerateReservedWord() - Generates a 30 bit word containing alternating     %
    %   one's and zero's for 24 bits, and 6 parity bits.                          %
    % --------------------------------------------------------------------------- %
    reserved_word = [ 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ];
end

function anti_spoof_word = GenerateAntiSpoofWord()
    % --------------------------------------------------------------------------- %
    % GenerateReservedWord() - Generates a 30 bit word containing anti spoof data %
    %   for 6 Sv. All of the data for each SV will be 1 0 0 1;
    % --------------------------------------------------------------------------- %
    anti_spoof_word = [ 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 ];
end

function erd_5_sv = GenerateERDWord()
    % --------------------------------------------------------------------------- %
    % GenerateReservedWord() - Generates a 30 bit word containing ERD data for 5  %
    %   SVs. Always the first SV will only have 4 bits of its ERD, while the last %
    %   SV will have only 2 bits of its ERD.
    % --------------------------------------------------------------------------- %
    erd_5_sv = [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];
end
