function [ output_args ] = ConvertToBytesAndPad( input_array )
% Function takes in a 10x30 array containg 300 bits. All bits of a subframe
% It will take these 300 bits and convert them to bytes ( 8-bit sections)
% and also adds two extra bits to each word (which are used to as selector
% bits).
[ number_of_rows , number_of_columns ] = ...
    size(input_array);

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
for count_rows = 1:1:number_of_rows
    % Break down each 8-bits into bytes
    
    
end