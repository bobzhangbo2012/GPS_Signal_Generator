function selected_bits = SelectSatellite( SV_number )
% ----------------------------------------------------------------------- %
%           SelectSatellite() - This function outputs two integer values  %
%  that refeers to the bit position of register G2. The bits selected     %
%  will be passed to registered that contol MUXes to select the specific  %
%  position. For example, to select Satelite Vehicle 9 pass the SV_number %
%  9 and expect the tap_bits to be 3 and 10.                              %
%                                                                         %
%       Input:  SV_number: The satellite vehicle to select                %
%                                                                         %
%       Output: selected_bits:  The two integers for the positon of the   %
%                               selected bits                             %
% ----------------------------------------------------------------------- %
%               Created by Kurt Pedrosa  -- Feb 20th 2017                 %
% ----------------------------------------------------------------------- %

    % Check to insure that the SV_number is between 1-37 ( number of possible
    % PRN signals)
    if (SV_number <= 37) && (SV_number > 0)

        % Define the possible selected patterns
        tap_bits = [ 2 6;
                     3 7;
                     4 8;
                     5 9;
                     1 9;
                     2 10;
                     1 8;
                     2 9;
                     3 10;
                     2 3;
                     3 4;
                     5 6;
                     6 7;
                     7 8;
                     8 9;
                     9 10;
                     1 4;
                     2 5;
                     3 6;
                     4 7;
                     5 8;
                     6 9;
                     1 3;
                     4 6;
                     5 7;
                     6 8;
                     7 9;
                     8 10;
                     1 6;
                     2 7;
                     3 8;
                     4 9;
                     5 10;
                     4 10;
                     1 7;
                     2 8;
                     4 10];

        selected_bits = tap_bits( SV_number, :);

        fprintf('Satellite Selected was %i.\n', SV_number );
        fprintf('The bits for Satellite %i are %i, %i.\n', SV_number, selected_bits(1,1), selected_bits(1,2));
        % print a empty line for spacing
        fprintf('\n');

    else
        error('Selected SV number is out of range.')
    end
end
