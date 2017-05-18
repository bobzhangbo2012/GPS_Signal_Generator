function [ encoded_message ] = GpsParityMaker( forced_parity, message, D_Star_2_bits )
% ----------------------------------------------------------------------- %
%     GpsParityMaker - Generates a 6-bit parity number given the 24-bit   %
%   message. This parity number is generated for each word in a subframe. %
%   The D* ( 2 bits ) are the two bits from the preceding message         %
%   required to calculate the parity bits. The algorithim used is         %
%   detailed in the Navstart IS-GPS-200D table 20-XIV.
%
%   IMPORTANT:  D_Star_2_bits must be [ D_29_start , D_30_start ].        %
%       Meaning, the 29th bit of the preceeding message has to be first   %
% ----------------------------------------------------------------------- %
%               Created by Kurt Pedrosa  -- Feb 20th 2017                 %
% ----------------------------------------------------------------------- %

    % Split D* bits
    D_29_star = D_Star_2_bits(1);
    D_30_star = D_Star_2_bits(2);

    if forced_parity == 0
    % Not a forced parity maker
        encoded_message_MSB = xor( message, D_30_star );
        parity_bits = ...
            CalculateParityBits( D_29_star, D_30_star, message );

        encoded_message = [ encoded_message_MSB parity_bits ];

    elseif forced_parity == 1
        % A forced parity maker. Bits 23 and 24 must be selected so that
        %   bits 29 and 20 of message are both zero.
        %   NOTE: Bit 23 and 24 are referred to as 't' in the documentation
        %   FYI: Bit 't' are present in HOW and Word 10 of each subframe
        if length( message ) == 22

            % Possible 't' choiced
            t_choices = [ 0 0; 0 1; 1 0; 1 1];
            % Iterate through each 't' possibility
            for count_i = 1:length(t_choices)

                message_24_bits = [ message t_choices( count_i, :) ];
                parity_bit_temp = ...
                    CalculateParityBits( D_29_star, D_30_star, message_24_bits );

                if (parity_bit_temp(5) == 0 && parity_bit_temp(6) == 0)

                    encoded_message_MSB = xor( message, D_30_star );
                    encoded_message = [ encoded_message_MSB t_choices( count_i, : ) parity_bit_temp ];

                end
            end
        else
            error('Forced Parity on given message error. Message not 22-bits long');
        end
    else
        % Not a valid input.
        error('Incorrect force parity request. Check parity maker');
    end
end

function parity_bits = ...
    CalculateParityBits( D_29_star, D_30_star, message_24_bits )

    % Compute all 6 parity bits.
    D_25 = ModularTwoAddition( D_29_star, message_24_bits, 25 );
    D_26 = ModularTwoAddition( D_30_star, message_24_bits, 26 );
    D_27 = ModularTwoAddition( D_29_star, message_24_bits, 27 );
    D_28 = ModularTwoAddition( D_30_star, message_24_bits, 28 );
    D_29 = ModularTwoAddition( D_30_star, message_24_bits, 29 );
    D_30 = ModularTwoAddition( D_29_star, message_24_bits, 30 );

    parity_bits = [  D_25 D_26 D_27 D_28 D_29 D_30 ];
end

function D_result = ModularTwoAddition( D_star, message, parity_bit )
% ----------------------------------------------------------------------- %
%     ModularTwoAddition - Takes in a D_star 1-bit number that is used    %
%   with the message ( a 24-bit number ) to calculate a single parity bit.%
%   The parity_bit is a identifier used by this function to calculate     %
%   the correct D_result.                                                 %
%                                                                         %
%   IMPORTANT:  The message_bits_for_calculation is defined by the GPS    %
%               document IS-GPS-200 Table 20-XIV. Any changes to this     %
%               needs to be reflected on this variable.                   %
% ----------------------------------------------------------------------- %
%               Created by Kurt Pedrosa  -- Feb 20th 2017                 %
% ----------------------------------------------------------------------- %

 % Set D_start to D_result so it can be used later for caluclation
 D_result = D_star;
 % Message must be a 24-bit number
 if ( length( message ) == 24 )
     % Define the message bits used for calculation depending on
     % the parity bit being calculated
     switch parity_bit
         case 25
             message_bits_for_calculation = ...
                 [ 1 2 3 5 6 10 11 12 13 14 17 18 20 23 ];
         case 26
             message_bits_for_calculation = ...
                 [ 2 3 4 6 7 11 12 13 14 15 18 19 21 24 ];
         case 27
             message_bits_for_calculation = ...
                 [ 1 3 4 5 7 8 12 13 14 15 16 19 20 22 ];
         case 28
             message_bits_for_calculation = ...
                 [ 2 4 5 6 8 9 13 14 15 16 17 20 21 23 ];
         case 29
             message_bits_for_calculation = ...
                 [ 1 3 5 6 7 9 10 14 15 16 17 18 21 22 24 ];
         case 30
             message_bits_for_calculation = ...
                 [ 3 5 6 8 9 10 11 13 15 19 22 23 24 ];
         otherwise
             error( 'Parity bit not defined');
     end

     % Calculate the parity bit
     for count_i = 1:length( message_bits_for_calculation )
         D_result = xor( D_result, message( message_bits_for_calculation( count_i ) ));
     end
 else
     error( 'Message is not 24-bits' );
 end
end
