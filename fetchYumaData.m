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
    % Note: calculation of day of the year sometime throws an error
    %   because it increases the current day faster than the website.
    current_date = clock;
    year = current_date(1);
    day_of_year = floor( now - datenum( year, 0, 1, 0, 0, 0 ));
    fprintf('Today is day number %d of the year %d.\n', day_of_year, year );

    % Fetch the data from the website
    base_url = 'https://gps.afspc.af.mil/gps/archive/2017/almanacs/yuma/';
    file_type = '.alm';
    full_url = strcat( base_url, num2str( day_of_year ), file_type );
    file_name = 'current_almanac';

    % Check Matlab version
    if verLessThan('matlab', 'R2014b') % Function websave() introduced in R2014b
       % Try
       disp('Fetching Yuma Almanac Data...');
       [ almanac_file, status ] = urlwrite( full_url, strcat(file_name, '.alm' ) );
       if status == 1
           disp('Done.')
       elseif strcmp( status, 'Error using urlreadwrite (line 98)')
           disp('Matlab does not have the YUMA almanac data website certificate as a trusted keystore.');
           disp('Go to https://www.mathworks.com/matlabcentral/answers/92506-how-can-i-configure-matlab-to-allow-access-to-self-signed-https-servers for a solution');
       else
           fprintf('%s\n', status);
       end
    else
        % If newer than R2015 use websave
        try
            disp('Fetching Yuma Almanac Data...');
            almanac_file = websave( file_name, full_url );

        catch ME
            if strcmp( ME.identifier, 'MATLAB:webservices:HTTP404StatusCodeError' )
                delete *.html *.alm;
                error('Web service 404 Error. Check website and Day of Year calculation.');
            else
                fprintf('%s\n', ME.identifier);
            end
        end
    end

    % Get YUMA data
    disp('Done.')
    data = ExtractData( almanac_file );

    % Clean up created file
    delete *.alm;
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
            id = ParseValueInCurrentLine( current_line );
            sv_data =  id ;
            current_line = fgetl( file_id ); % Go to next line
            % Get health
            if strfind( current_line, 'Health')
                health = ParseValueInCurrentLine( current_line );
                sv_data = [ sv_data health ];
                current_line = fgetl( file_id ); % Go to next line
                % Get Eccentricity
                if strfind( current_line, 'Eccentricity' )
                    eccentricity = ParseValueInCurrentLine( current_line );
                    sv_data = [ sv_data eccentricity ];
                    current_line = fgetl( file_id );
                    % Get Time of Applicability
                    if strfind( current_line, 'Time of Applicability')
                        time_of_app = ParseValueInCurrentLine( current_line );
                        sv_data = [ sv_data time_of_app ];
                        current_line = fgetl( file_id );
                        % Get Orbital Inclination
                        if strfind( current_line, 'Orbital Inclination' )
                            orbital_incl = ParseValueInCurrentLine( current_line );
                            sv_data = [ sv_data orbital_incl ];
                            current_line = fgetl( file_id );
                            % Get Rate of Right Ascen
                            if strfind( current_line, 'Rate of Right Ascen')
                                rate_of_right_ascen = ParseValueInCurrentLine( current_line );
                                sv_data = [ sv_data rate_of_right_ascen ];
                                current_line = fgetl( file_id );
                                % Get SQRT(A)
                                if strfind( current_line, 'SQRT(A)')
                                    sqroot_a = ParseValueInCurrentLine( current_line );
                                    sv_data = [ sv_data sqroot_a ];
                                    current_line = fgetl( file_id );
                                    % get Right Ascen at Week
                                    if strfind( current_line, 'Right Ascen at Week')
                                        ascen_at_week = ParseValueInCurrentLine( current_line );
                                        sv_data = [ sv_data ascen_at_week ];
                                        current_line = fgetl( file_id );
                                        % Get Argument of Perigee
                                        if strfind( current_line, 'Argument of Perigee')
                                            arg_perigee = ParseValueInCurrentLine( current_line );
                                            sv_data = [ sv_data arg_perigee ];
                                            current_line = fgetl( file_id );
                                            % Get Mean Anom
                                            if strfind( current_line, 'Mean Anom')
                                                mean_anom = ParseValueInCurrentLine( current_line );
                                                sv_data = [ sv_data mean_anom ];
                                                current_line = fgetl( file_id );
                                                % Get Af0
                                                if strfind( current_line, 'Af0' )
                                                    af0 = ParseValueInCurrentLine( current_line );
                                                    sv_data = [ sv_data af0 ];
                                                    current_line = fgetl( file_id );
                                                    if strfind( current_line, 'Af1')
                                                        af1 = ParseValueInCurrentLine( current_line );
                                                        sv_data = [ sv_data af1 ];
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

% ----------------------------------------------------------------------- %
%   ParseValueInCurrentLine() - This function takes in the current line   %
%   being read and finds the value at the end-of-the-line. For example    %
%   ID:             32          will return the number 32                 %
%   SQRT(A)  (m 1/2)            5153.687012  will return 5153.687012      %
%                                                                         %
%       Important: A YUMA almanac file expected                           %
% ----------------------------------------------------------------------- %
%               Created by Kurt Pedrosa  -- May 18th 2017                 %
% ----------------------------------------------------------------------- %
function parsed_value = ParseValueInCurrentLine( current_line )
    for count_char = 0:length( current_line ) - 1
        if strcmp( current_line( end-count_char ), ' ' )
            parsed_value = str2double( current_line( end - ( count_char - 1 ):end )) ;
            break;
        end
    end
end
