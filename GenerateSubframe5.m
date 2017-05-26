function subframe_5_300_bits  = GenerateSubframe5( ...
    page_number, full_almanac_data, full_sv_health_data,...
    GPS_week_number, TOW_truncated, D_star  )
    % ----------------------------------------------------------------------- %
    %  GenerateSubframe5 - Generates the second subframe of a GPS Message. It %
    %   contains 300 bits, 10 words each 30 bits. The following define each   %
    %   bit content:                                                          %
    %                                                                         %
    %   Pages 1 - 24:                                                         %
    %       Word 1 - TLM                                                      %
    %       Word 2 - HOW                                                      %
    %       Word 3 - Data ID (2-bits), SV Id (6-bit), e (16-bits)             %
    %       Word 4 - t_oa (8-bits), delta_i (16-bits)                         %
    %       Word 5 - omega_dot (16-bits), sv_health (8-bits)                  %
    %       Word 6 - sqrt_a (24-bits)                                         %
    %       Word 7 - omega_not (24-bits)                                      %
    %       Word 8 - omega (24 bits LSB)                                      %
    %       Word 9 - M_not ( 24-bits)                                         %
    %       Word 10 - a_f_not (8-bits MSB ), a_f_1 ( 11-bts ),                %
    %                 a_f_not (2-bit LSB)                                     %
    %                                                                         %
    %       INPUT:                                                            %
    %         - page_nuber - Subframe 4 and 5 have page numbers               %
    %         - TOW_truncated - 17 MSB of 19 bit time of week                 %
    %         - D_star -  Last two bits of previews word                      %
    %         - full_almanac_data - All of the Yuma data for given SV         %
    %         - full_sv_health_data - Health data for ALL SVs                 %
    %         - GPS_week_number - Current GPS week                            %
    %                                                                         %
    % ----------------------------------------------------------------------- %
    %               Created by Kurt Pedrosa  -- March 03th 2017               %
    % ----------------------------------------------------------------------- %

    % Insure page number is between 1-25
    if page_number < 0 || page_number > 25
        error('Incorrect page number in Subframe 5.');
    end

    % Define Frame
    frame_id = [ 1 0 1 ];
    % Define all  300 bits, 10 words.
    word_1  = GenerateTLMWord( D_star );
    word_2  = GenerateHOWWord( TOW_truncated, frame_id, word_1( 29:30 ));
    word_3  = GenerateWord3(...
                page_number, full_almanac_data( 2 ) , full_almanac_data( 3 ),...
                full_almanac_data( 4 ), GPS_week_number, word_2( 29:30 ) );
    word_4  = GenerateWord4(...
                page_number, full_almanac_data( 4 ),...
                full_sv_health_data( 1:4 ), word_3(29:30) );
    word_5  = GenerateWord5(...
                page_number, full_almanac_data( 6 ), full_sv_health_data( 2 ),...
                full_sv_health_data( 5:8 ), word_4(29:30) );
    word_6  = GenerateWord6(...
                page_number, full_almanac_data( 7 ),...
                full_sv_health_data( 9:12 ), word_5(29:30) );
    word_7  = GenerateWord7( page_number, full_sv_health_data( 13:16 ),...
                word_6(29:30) );
    word_8  = GenerateWord8(...
                page_number, full_almanac_data( 9 ),...
                full_sv_health_data( 17:20 ), word_7(29:30) );
    word_9  = GenerateWord9(...
                page_number, full_almanac_data( 10 ),...
                full_sv_health_data( 21:24 ), word_8(29:30) );
    word_10 = GenerateWord10(...
                page_number, full_almanac_data( 11 ),...
                full_almanac_data( 12 ), word_9(29:30) );

    % Returns a array of 10 x 30 bits
    %   Each row is a word. For example
    %      + To access word 8 - subframe_1_300_bits( 8, : )
    %      + To access word 10 bit 29 and 30  - subframe_1_300_bits( 10, (29:30) );
    subframe_5_300_bits = [ word_1 ;
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


function word_3 = GenerateWord3( ...
    page_number, sv_health, sv_eccentricity, sv_t_oa, GPS_week_number, D_star )
% --------------------------------------------------------------------------- %
% GenerateWord3() - Generates a 30 bit word containing:                       %
%  Pages 1 - 24 -- Data ID (2 bits), SV id (6 bits), Eccentricity ( 16 bits ) %
%  Page 25 -- Data ID (2 bits), SV id (6 bits), Time of Applicabitity(8 bits) %
%             Almanac Reference Week (8 bits)                                 %
% --------------------------------------------------------------------------- %
    if page_number < 25
        % Define Data_id
        %   For NAV data data_id must be [ 0 1 ] (2)
        data_id = [ 0 1 ];
        % Define SV_id
        % Catch for dummy SV
        if sv_health == 63
            sv_id = str2bin_array( dec2bin( 0, 6 ) );
        else
            sv_id = str2bin_array( dec2bin( page_number, 6 ) );
        end

        % Define eccentricity
        % Check range
        if (sv_eccentricity < 0.0 || sv_eccentricity > 0.03) && sv_eccentricity ~= 0.0208330154418945
            eccentricity = dec2bin( 0, 16 );
            error( 'Eccentricity value passed is out-of-range. Check Word 3 Subframe 5.' );
        else
            %eccentricity = [ 1 1 0 1 0 0 0 1 0 0 1 0 1 1 0 0 0 0 0 0 0 0 1 0 ]; % test
            eccentricity = SvData2Binary( sv_eccentricity/2^-21, 16);
        end

        % Pack'em all into a 24-bit number
        word_3_no_parity = [ data_id sv_id eccentricity ];
    else
        % Define Data_id
        %   For NAV data data_id must be [ 0 1 ] (2)
        data_id = [ 0 1 ];
        % Define SV_id
        % Catch for dummy SV
        if sv_health == 63
            sv_id = str2bin_array( dec2bin( 0, 6 ) );
        else
            sv_id = str2bin_array( dec2bin( 51, 6 ) );
        end
        % Define t_oa (8 bits)
        %Check range
       if ( sv_t_oa > 602112  || sv_t_oa < 0 ) && sv_t_oa ~= 696320
           t_oa = bin2dec( 0, 8 );
           error('The Time of Applicabitity is out-of-range. Check Word 3 of Subframe 5.');
       else
           t_oa = SvData2Binary( sv_t_oa/ 2^12, 8 );
       end
        % Define wn_a (8 bits)
        % A modulo 256 8-bit of the GPS week number
        wn_a = str2bin_array( dec2bin( mod( GPS_week_number, 256 ), 8) );

        % Pack'em all into a 24-bit number
        word_3_no_parity = [ data_id sv_id t_oa wn_a ];
    end

    word_3 = GpsParityMaker( 0, word_3_no_parity, D_star );
end

function word_4 = GenerateWord4( ...
    page_number, sv_t_oa, full_sv_health_data, D_star )
% --------------------------------------------------------------------------- %
% GenerateWord3() - Generates a 30 bit word containing:                       %
%  Pages 1 - 24 -- Time of Applicabitity (8 bits)                               %
%  Page 25 -- Satellite health SV 1, 2, 3, and 4                              %
% --------------------------------------------------------------------------- %
    if page_number < 25
        % Define t_oa (8 bits)
        % Check range
        if  sv_t_oa > 602112 || sv_t_oa < 0
            t_oa = dec2bin( 0, 8 );
            error('The Time of Applicabitity is out-of-range. Check Word 4 of Subframe 5.');
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
    else
        % Define SV Health for SV 1, 2, 3, 4
        % 6-bit for each SV ( 24 bits total )
        sv_1_health = str2bin_array( dec2bin( full_sv_health_data( 1 ), 6 ));
        sv_2_health = str2bin_array( dec2bin( full_sv_health_data( 2 ), 6 ));
        sv_3_health = str2bin_array( dec2bin( full_sv_health_data( 3 ), 6 ));
        sv_4_health = str2bin_array( dec2bin( full_sv_health_data( 4 ), 6 ));

        % Pack'em all into a 24-bit number
        word_4_no_parity = [ sv_1_health sv_2_health sv_3_health sv_4_health ];
    end


    word_4 = GpsParityMaker( 0, word_4_no_parity, D_star ) ;
end

function word_5 = GenerateWord5(...
    page_number, sv_omega_dot, sv_health, full_sv_health_data, D_star )
% --------------------------------------------------------------------------- %
% GenerateWord5() - Generates a 30 bit word containing:                       %
%  Pages 1 - 24 -- Rate of Right Ascension (24 bits)                          %
%  Page 25 -- Satellite health SV 5, 6, 7, and 8                              %
% --------------------------------------------------------------------------- %
        if page_number < 25
            % Define omega_dot (16-bits)
            omega_dot_dec = sv_omega_dot/pi;

            % Check range
            if omega_dot_dec < -6.33E-07  || omega_dot_dec > 0
              omega_dot = bin2dec( 0, 24 );
                error('The Rate of Right Ascension is out-of-range. Check Word 5 of Subframe 5');
            else
                omega_dot = SvData2Binary( omega_dot_dec/ 2^-38, 16 );
            end
            % Define SV Health
            health = SvData2Binary( sv_health, 8 );

            % Pack'em all into a 24-bit number
            word_5_no_parity = [ omega_dot health ];
        else
            % Define SV Health for SV 5,6,7,8
            % 6-bit for each SV ( 24 bits total )
            sv_5_health = str2bin_array( dec2bin( full_sv_health_data( 1 ), 6 ));
            sv_6_health = str2bin_array( dec2bin( full_sv_health_data( 2 ), 6 ));
            sv_7_health = str2bin_array( dec2bin( full_sv_health_data( 3 ), 6 ));
            sv_8_health = str2bin_array( dec2bin( full_sv_health_data( 4 ), 6 ));

            % Pack'em all into a 24-bit number
            word_5_no_parity = [ sv_5_health sv_6_health sv_7_health sv_8_health ];
        end

    word_5 = GpsParityMaker( 0, word_5_no_parity, D_star );
end

function word_6 = GenerateWord6( page_number, sv_sqrt_a, full_sv_health_data, D_star )
% --------------------------------------------------------------------------- %
% GenerateWord3() - Generates a 30 bit word containing:                       %
%  Pages 1 - 24 -- Square Root of Semi-Major Axis (24 bits)                   %
%  Page 25 -- Satellite health SV 9, 10 ,11, and 12                           %
% --------------------------------------------------------------------------- %
    if page_number < 25
        % Define sqrt_a ( 24 bits )
        % Check range
        sqrt_a_dec = sv_sqrt_a;

        if sqrt_a_dec < 2530 || sqrt_a_dec > 8192
            sqrt_a = bin2dec( 0, 24 );
            error('Squre Root of the Semi-Major Axis is out-of-range. Check Word 8 of Subframe 2.');
        else
            sqrt_a = SvData2Binary( sqrt_a_dec/2^-11, 24 );
        end

        % Pack'em all into a 24-bit number
        word_6_no_parity = sqrt_a;
    else
        % Define SV Health for SV 9,10,11,12
        % 6-bit for each SV ( 24 bits total )
        sv_9_health = str2bin_array( dec2bin( full_sv_health_data( 1 ), 6 ));
        sv_10_health = str2bin_array( dec2bin( full_sv_health_data( 2 ), 6 ));
        sv_11_health = str2bin_array( dec2bin( full_sv_health_data( 3 ), 6 ));
        sv_12_health = str2bin_array( dec2bin( full_sv_health_data( 4 ), 6 ));

        % Pack'em all into a 24-bit number
        word_6_no_parity = [ sv_9_health sv_10_health sv_11_health sv_12_health ];
    end

    word_6 = GpsParityMaker(0,  word_6_no_parity, D_star );
end

function word_7 = GenerateWord7( page_number, full_sv_health_data, D_star )
% --------------------------------------------------------------------------- %
% GenerateWord3() - Generates a 30 bit word containing:                       %
%  Pages 1 - 24 -- Longitude of Ascending Node ( 24 bits )                    %
%  Page 25 -- Satellite health SV 13, 14, 15, and 16                          %
% --------------------------------------------------------------------------- %
    if page_number < 25
        % Define omega_not
        % omega_not is the Longitude of Ascending Node of Orbit Plane at Weekly Epoch
        % omega_not is 24-bit
        % omega_not has a Scale Factor of 2^-31 and measured in semi-circles
        % Note: No observed date was found online. Value of zero chosen for simulation
        %   omega_not = 0 = 0/2^-23 = 0 = 00000000 MSB 000000000000000000000000b
        omega_not = [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ];

        word_7_no_parity = omega_not;
    else
        % Define SV Health for SV 13,14,15,16
        % 6-bit for each SV ( 24 bits total )
        sv_13_health = str2bin_array( dec2bin( full_sv_health_data( 1 ), 6 ));
        sv_14_health = str2bin_array( dec2bin( full_sv_health_data( 2 ), 6 ));
        sv_15_health = str2bin_array( dec2bin( full_sv_health_data( 3 ), 6 ));
        sv_16_health = str2bin_array( dec2bin( full_sv_health_data( 4 ), 6 ));

        % Pack'em all into a 24-bit number
        word_7_no_parity = [ sv_13_health sv_14_health sv_15_health sv_16_health ];
    end

    word_7 = GpsParityMaker( 0, word_7_no_parity, D_star );
end

function word_8 = GenerateWord8(...
    page_number, sv_omega, full_sv_health_data, D_star )
% --------------------------------------------------------------------------- %
% GenerateWord3() - Generates a 30 bit word containing:                       %
%  Pages 1 - 24 --  Argument of Perigee (24 bits)                             %
%  Page 25 -- Satellite health SV 17, 18, 19, and 20                          %
% --------------------------------------------------------------------------- %
    if page_number < 25
        omega = SvData2Binary( (sv_omega/pi)/2^-23, 24 );

        word_8_no_parity = omega;
    else
        % Define SV Health for SV 17,18,19,20
        % 6-bit for each SV ( 24 bits total )
        sv_17_health = str2bin_array( dec2bin( full_sv_health_data( 1 ), 6 ));
        sv_18_health = str2bin_array( dec2bin( full_sv_health_data( 2 ), 6 ));
        sv_19_health = str2bin_array( dec2bin( full_sv_health_data( 3 ), 6 ));
        sv_20_health = str2bin_array( dec2bin( full_sv_health_data( 4 ), 6 ));

        % Pack'em all into a 24-bit number
        word_8_no_parity = [ sv_17_health sv_18_health sv_19_health sv_20_health ];
    end

    word_8 = GpsParityMaker( 0, word_8_no_parity, D_star );
end

function word_9 = GenerateWord9( page_number, sv_M_not, full_sv_health_data, D_star )
% --------------------------------------------------------------------------- %
% GenerateWord3() - Generates a 30 bit word containing:                       %
%  Pages 1 - 24 -- Mean Anomoly at Ref Time ( 24 bits )                       %
%  Page 25 -- Satellite health SV 21, 22, 23, and 24                          %
% --------------------------------------------------------------------------- %
    if page_number < 25
        % Define M_not
        %   M_not is the Mean Anomaly at Reference Time
        %   M_not has 32 bits ( 8-bits in word 4 of Subframe 2 )
        %   M_not has a Scale Factor of 2^-31
        %   M_not = 0 semi-circles = 0/(2^-31) = 0 semi-circles
        %   M_not = 1.41596 rad = 0.4507140664408 semi-circles ...
        %       = 0.4507140664408/(2^-31) = 9.6790 e8
        %       = 00111001 101100001111111110011111 binary
        %   Note: 1 sem-circle = 3.1415926535 radians
        M_not =  SvData2Binary( ( sv_M_not/pi )/( 2^-23 ), 24 );

        word_9_no_parity = M_not;
    else
        % Define SV Health for SV 17,18,19,20
        % 6-bit for each SV ( 24 bits total )
        sv_21_health = str2bin_array( dec2bin( full_sv_health_data( 1 ), 6 ));
        sv_22_health = str2bin_array( dec2bin( full_sv_health_data( 2 ), 6 ));
        sv_23_health = str2bin_array( dec2bin( full_sv_health_data( 3 ), 6 ));
        sv_24_health = str2bin_array( dec2bin( full_sv_health_data( 4 ), 6 ));

        % Pack'em all into a 24-bit number
        word_9_no_parity = [ sv_21_health sv_22_health sv_23_health sv_24_health ];
    end

    word_9 = GpsParityMaker( 0, word_9_no_parity, D_star );
end

function word_10 = GenerateWord10( page_number, sv_a_f0, sv_a_f1, D_star )
% --------------------------------------------------------------------------- %
% GenerateWord3() - Generates a 30 bit word containing:                       %
%  Pages 1 - 24 -- a_f0 (11 bits) and  a_f1(11 bits)%                         %
%  Page 25 -- System Reserved bits (6 bits) and Reserved bits (16 bits)       %
% --------------------------------------------------------------------------- %
    if page_number < 25
        a_f0 = SvData2Binary( sv_a_f0/( 2^-20 ), 11);
        a_f1 = SvData2Binary( sv_a_f1/( 2^-38 ), 11);

        word_10_no_parity = [ a_f0(1:8) a_f1 a_f0(9:11) ];
    else
        reserved_system_use = [ 1 0 1 0 1 0 ]; % 6 bits
        reserved = [ 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ]; % 16 bits

        % Pack'em all into a 22-bit number THIS HAS FORCE PARITY!
        word_10_no_parity = [ reserved_system_use reserved ];
    end

    word_10 = GpsParityMaker( 1, word_10_no_parity, D_star );
end
