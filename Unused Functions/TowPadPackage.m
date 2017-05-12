function [ time_of_week ] = TowPadPackage( time_of_week_decimal, msb_flag )
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
%                                                                         %
%      CHANGE LOG:                                                        %
%                                                                         %
%   + by Kurt: Added a flag to give the function the option to return all %
%       19 bits or just the 17 MSB ( bits 1 ... 17 ). This is used when   %
%       calculating new TOW values for each subframe.                     %
%                           May 9th 2017                                  %
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
            [ pad str2bin_array( binary_equivalent )];
    else
        time_of_week_19_bits =  str2bin_array( binary_equivalent );
    end

    % Choose the output depending on the flagged passed.
    if msb_flag == 1
        time_of_week = time_of_week_19_bits( 1:17 );
    elseif msb_flag == 0
        time_of_week = time_of_week_19_bits;
    else
        error('MSB Flag passed to TowPadPackage is not valid.');
    end

end
