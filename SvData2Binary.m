% ----------------------------------------------------------------------- %
%  SvData2Binary() - This function take a SV value, checks if its a       %
%    negative number ( if so, take two's complement of said value ) and,  %
%    converts it to a binary array. For example:                          %
%                                                                         %
%              -7.4586e+08 =
%                                                                         %
% ----------------------------------------------------------------------- %
%               Created by Kurt Pedrosa  -- May 19th 2017                 %
% ----------------------------------------------------------------------- %
function sv_data_binary = SvData2Binary( sv_data_dec, num_of_bits )
        % Check if value is negative
        if sv_data_dec < 0
            % Make it a positive
            temp_sv_data_dec = -1 * sv_data_dec;

            % Convert to binary array. For example '1010' = [1 0 1 0]
            temp_sv_data_bin = str2bin_array( dec2bin( temp_sv_data_dec, num_of_bits ));

            % Take Two's complement
            temp_sv_data_bin = xor( temp_sv_data_bin, 1 ); % Invert all bits
            carry_bit = 1;
            temp_bin = [ ];
            for count_bits = num_of_bits:-1:1
                if ( temp_sv_data_bin( count_bits ) + carry_bit == 2 )
                    temp_bin = [ 0 temp_bin ];
                    carry_bit = 1;
                elseif ( temp_sv_data_bin( count_bits ) + carry_bit == 1 )
                    temp_bin = [ 1 temp_bin ];
                    carry_bit = 0;
                else
                    temp_bin = [ 0 temp_bin ];
                    carry_bit = 0;
                end
            end
            % Return negative binary representation of value.
            sv_data_binary = temp_bin;
        else
            % Value is positive, convert to binary array and return.
            sv_data_binary = str2bin_array( dec2bin( sv_data_dec, num_of_bits ));
        end
end
