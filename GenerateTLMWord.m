function [ TLM_word ] = GenerateTLMWord( D_star )
% ----------------------------------------------------------------------- %
%     GenerateTLMWOrd - Generates all 30 bits of the TLM word. The TLM    %
%  word is the first word of each subframe. Begins with a preamble,       %
%  followed by the TLM Message ( which in this case is a 14-bit number    %
%  with all 0's , one (1) reserved bits, a integrity flag  and six (6)    %
% parity bits. The input D_start is a 2-bit vector that hold the last two %
% bits of the previews word which is used in calculating the parity bits. %
%                                                                         %
%   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ %
%   +    Preamble     +       TLM Message           + Rsr +   Parity    + %
%   + 1 0 0 0 1 0 1 1 + 1 1 1 1 1 1 1 1 1 1 1 1 1 1 + 1 1 + x x x x x x + %
%   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ %
%     1                 9                             23    25      30    %
%                                                                         %
% ----------------------------------------------------------------------- %
%               Created by Kurt Pedrosa  -- Feb 20th 2017                 %
% ----------------------------------------------------------------------- %

% Define the preamble ( 8-bits )
TLM_preamble = [1 0 0 0 1 0 1 1];

% Define the TLM message ( 14 -bits )
TLM_message = zeros(1 ,14);

% Integrity status flag
integrity_status_flag = 1;
% Reserve bits
TLM_reserve = 1;

% Pack'em into a 24-bit number
TLM_word = [ TLM_preamble TLM_message integrity_status_flag TLM_reserve ];

% Calculate parity bits ( 6-bits )
TLM_word = [ TLM_word GpsParityMaker( 0, TLM_word, D_star )  ];

end
