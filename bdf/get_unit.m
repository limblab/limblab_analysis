function s = get_unit( data, channel, unit )
% GET_UNIT - timestamps for a particular unit
%   S = GET_UNIT( DATA, CHANNEL, UNIT) returns the list of timestamps S for
%   a particular unit contained in BDF DATA.  CHANNEL contains the channel
%   of the unit, and UNIT contains the sort code.
%
%   This will throw an exception of the specified unit cannot be found;
%   however, if the unit is defined but contains no spikes, it will return
%   a null list with no error.

% $Id$

unit_num = -1;
num_units = size(data.units, 2);

for i = 1:num_units
    if all(data.units(i).id == [channel unit])
        unit_num = i;
        break
    end
end

if unit_num == -1
    error('specified unit not found');
end

s = data.units(unit_num).ts;
