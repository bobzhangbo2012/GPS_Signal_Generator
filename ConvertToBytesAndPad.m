function [ byte_array ] = ConvertToBytesAndPad( input_array )
% ----------------------------------------------------------------------- %
%           ConvertToBytesAndPad - This takes in a 10 by 30 array         %
%   containg 300 bits, 30 bits from 10 words in a GPS subframe. All bits  %
%   of a single subframe will be reshaped, converted to bytes and padded  %
%   with two extra bits in the LSB location.                              %
%                                                                         %
%   Input --    input_array: A 10 by 30 array containg 0's and 1's (bits) %
%                                                                         %
%   Output -- reshaped_array: A 4 by 10 array holding byte values for     %
%                   for each 8 -bits.                                     %
%                                                                         %
% ----------------------------------------------------------------------- %
%               Created by Kurt Pedrosa  -- May 5th 2017                  %
% ----------------------------------------------------------------------- %
    [ number_of_rows , number_of_columns ] = ...
        size(input_array)

    % Create a temp array to hold values
    % This is a 4 by 10 array because each column will hold 32 bits divided by
    % 8 bits ( 1 Byte ). For example:
    %
    %   +---------------------------------------+
    %   | word_1( 32 - 24 ) | word_2( 32 - 24 ) |
    %   | word_1( 23 - 16 ) | word_2( 23 - 16 ) |
    %   | word_1( 15 - 8 )  | word_2( 15 - 8 )  |
    %   | word_1( 7 - 0 )   | word_2( 7  - 0 )  |
    %   +---------------------------------------+
    byte_array_temp = zeros(4,10);

    % Iterate thru each row
    for count_rows = 1:number_of_rows
        % Break down each 8-bits into bytes
        byte_array( 1, count_rows ) = Convert2Byte( input_array( count_rows, 1:8 ));
        byte_array( 2, count_rows ) = Convert2Byte( input_array( count_rows, [ 9:16 ] ));
        byte_array( 3, count_rows ) = Convert2Byte( input_array( count_rows, [ 17:24 ] ));
        byte_array( 4, count_rows ) = Convert2Byte( [ input_array( count_rows, [ 25:30 ]) 0 0 ] ); % Padding two bits at the LSB

    end
end



function byte_value = Convert2Byte( eight_bits_input )
    % Ensure only 8-bits are beingh received
    if length( eight_bits_input ) == 8

        byte_value = '';
        % Takes in an array. First need to be converted to a string so it
        %   can be used by the bin2dec() function.
        for count_bits = 1:8
            if eight_bits_input( count_bits ) == 1
                bit = '1';
                byte_value = [ byte_value bit ];
            else
                bit = '0';
                byte_value = [ byte_value bit ];
            end
        end

        % Convert binary to decimal and return it
        byte_value = bin2dec( byte_value );

    else
        error( 'Binary number passed is not an 8-bit number.')
    end
end
