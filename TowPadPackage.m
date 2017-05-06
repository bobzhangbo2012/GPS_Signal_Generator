function [ time_of_week_19_bits ] = TowPadPackage( time_of_week_decimal )
% ----------------------------------------------------------------------- %
%           TowPadPackage - Tow ( Time of Week ) Pad and Package          %
%    This function takes in a  decimal number between 0 - 403,199 and     %
%    and converts it to a n-bit (1 bit to 19 bits possible ) GPS          %
%   that represent the number of 1.5 seconds that happen in current GPS   % 
%   week. It will then pad the upper bits to make a 19 bit number with    %
%   leading zeros. The MSB 10 bits is then returned. Output is between    %
%   0 - 403,199.                                                          %
% ----------------------------------------------------------------------- %
%               Created by Kurt Pedrosa  -- Feb 20th 2017                 %
% ----------------------------------------------------------------------- %

    % Take decimal and convert it binary
    binary_equivalent = dec2bin( time_of_week_decimal );
    
    % Check length of binary number. If smaller than 19 bits it must be
    % padded with leading zeros
    if length( binary_equivalent ) < 19
        % Find how much needs padding
        pad_bin_amount = abs( length( binary_equivalent ) - 19 );
        % Create pad array
        pad = zeros( 1, pad_bin_amount);
        % Package the pad and binary
        time_of_week_19_bits = ...
            [ pad str2bin_array( dec2bin( time_of_week_decimal) )];
    else
        time_of_week_19_bits =  str2bin_array( dec2bin( time_of_week_decimal ) );
    end
end

