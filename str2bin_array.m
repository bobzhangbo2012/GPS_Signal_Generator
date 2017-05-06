function [ binary_number ] = str2bin_array( binary_number_as_string )
    
    size_of_binary_number = length( binary_number_as_string );
    binary_number_temp = zeros(1, size_of_binary_number );
    
    for count_i = 1:size_of_binary_number
        if binary_number_as_string(count_i) == '1'
            binary_number_temp(count_i) = 1;
        elseif binary_number_as_string(count_i) == '0'
            binary_number_temp(count_i) = 0;
        else
            error('String passed is not a binary number');
        end
    end

    binary_number = binary_number_temp;
end

