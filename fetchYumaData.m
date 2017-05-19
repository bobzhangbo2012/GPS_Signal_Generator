% ----------------------------------------------------------------------- %
%   fetchYmaData() - This function fetches the current almanac data for   %
%   the given day. It calculates the current day of the year and reads    %
%   date from the 2nd Spce Operation Squadron website:                    %
%                   https://gps.afspc.af.mil/gps/archive/                 %
%                                                                         %
% ----------------------------------------------------------------------- %
%               Created by Kurt Pedrosa  -- May 18th 2017                 %
% ----------------------------------------------------------------------- %
function data = fetchYumaData()
    % Get day of the year
    day_of_year = floor( now - datenum( 2017, 1, 1, 0, 0, 0 ));

    % Fetch the data from the website
    base_url = 'https://gps.afspc.af.mil/gps/archive/2017/almanacs/yuma/';
    file_type = '.alm';
    full_url = strcat( base_url, num2str( day_of_year ), file_type );
    file_name = 'current_almanac';

    try
        almanac_file = websave( file_name, full_url );
    catch ME
        if strcmp( ME.identifier, 'MATLAB:webservices:HTTP404StatusCodeError' )
            delete *.html *.alm;
            error('Web service 404 Error. Check website and Day of Year calculation.');
        else
            fprintf('%s\n', ME.identifier);
        end
    end

    data = ExtractData( almanac_file );


end

% ----------------------------------------------------------------------- %
%   ExtractData() - This function takes in a file, reads through the file %
%   extracting the data for each satellite and storying it into an array  %
%                                                                         %
%       Important: A YUMA almanac file expected                           %
% ----------------------------------------------------------------------- %
%               Created by Kurt Pedrosa  -- May 18th 2017                 %
% ----------------------------------------------------------------------- %
function all_sv_data = ExtractData( almanac_file )
    all_sv_data = [];
    % Open file
    file_id = fopen( almanac_file );

    % Read file
    current_line = fgetl( file_id );
    while ~feof( file_id )
        % If current line is the SV ID start saving info
        if strfind( current_line, 'ID')
            sv_data = [ str2num( current_line( end-2:end )) ]; % get SV ID
            current_line = fgetl( file_id ); % Go to next line
            % Get health
            if strfind( current_line, 'Health')
                sv_data = [ sv_data str2num( current_line( end-2:end )) ];
                current_line = fgetl( file_id ); % Go to next line
                % Get Eccentricity
                if strfind( current_line, 'Eccentricity' )
                    sv_data = [ sv_data str2double( current_line( end-16:end ))];
                    current_line = fgetl( file_id );
                    % Get Time of Applicability
                    if strfind( current_line, 'Time of Applicability')
                        % Check size of number
                        if strcmp( current_line( end-10 ), ' ' )
                            % This is a 9 digit number
                            sv_data = [ sv_data str2num( current_line( end-9:end ))];
                        else
                            % It is a 10 digit number
                            sv_data = [ sv_data str2num( current_line( end-10:end ))];
                        end
                        current_line = fgetl( file_id );
                        % Get Orbital Inclination
                        if strfind( current_line, 'Orbital Inclination' )
                            sv_data = [ sv_data str2double( current_line( end-11:end ))];
                            current_line = fgetl( file_id );
                            % Get Rate of Right Ascen
                            if strfind( current_line, 'Rate of Right Ascen')
                                for count_char_1 = 0:length( current_line )-1
                                    if strcmp( current_line( end-count_char_1 ), ' ')
                                        sv_data = [ sv_data str2double( current_line( end-( count_char_1-1 ):end )) ];
                                        break;
                                    end
                                end
                                current_line = fgetl( file_id );
                                % Get SQRT(A)
                                if strfind( current_line, 'SQRT(A)')
                                    sv_data = [ sv_data str2double( current_line( end-10:end )) ];
                                    current_line = fgetl( file_id );
                                    % get Right Ascen at Week
                                    if strfind( current_line, 'Right Ascen at Week')
                                        for count_char_2 = 0:length( current_line )-1
                                            if strcmp( current_line( end-count_char_2 ), ' ' )
                                                sv_data = [ sv_data str2double( current_line( end-( count_char_2-1 ):end )) ];
                                                break;
                                            end
                                        end
                                        current_line = fgetl( file_id );
                                        % Get Argument of Perigee
                                        if strfind( current_line, 'Argument of Perigee')
                                            for count_char_3 = 0:length( current_line )-1
                                                if strcmp( current_line( end-count_char_3 ), ' ' )
                                                    sv_data = [ sv_data str2double( current_line( end-( count_char_3-1 ):end )) ];
                                                    break;
                                                end
                                            end
                                            current_line = fgetl( file_id );
                                            % Get Mean Anom
                                            if strfind( current_line, 'Mean Anom')
                                                for count_char_4 = 0:length( current_line )-1
                                                    if strcmp( current_line( end-count_char_4 ), ' ' )
                                                        sv_dat = [ sv_data str2double( current_line( end-( count_char_4-1 ):end )) ];
                                                        break;
                                                    end
                                                end
                                                current_line = fgetl( file_id );
                                                % Get Af0
                                                if strfind( current_line, 'Af0' )
                                                    for count_char_5 = 0:length( current_line )-1
                                                        if strcmp( current_line( end-count_char_5 ), ' ')
                                                            sv_data = [ sv_data str2double( current_line( end-( count_char_5-1 ):end )) ];
                                                            break;
                                                        end
                                                    end
                                                    current_line = fgetl( file_id );
                                                    % Get Af1
                                                    for count_char_6 = 0:length( current_line )-1
                                                        if strcmp( current_line( end-count_char_6 ), ' ')
                                                            sv_data = [ sv_data str2double( current_line( end-( count_char_6-1 ):end )) ];
                                                            break;
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            % Complie all the data into one array
            % Referenced by SV ID as the first element on each row
            all_sv_data = [ all_sv_data; sv_data ];
        end
        current_line = fgetl( file_id );
    end

    fclose( file_id );
end
