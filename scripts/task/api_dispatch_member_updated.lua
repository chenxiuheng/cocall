require('conference.conferenceService');

local oct_to_hex = {}
    oct_to_hex[0] = '0';
    oct_to_hex[1] = '1';
    oct_to_hex[2] = '2';
    oct_to_hex[3] = '3';
    oct_to_hex[4] = '4';
    oct_to_hex[5] = '5';
    oct_to_hex[6] = '6';
    oct_to_hex[7] = '7';
    oct_to_hex[8] = '8';
    oct_to_hex[9] = '9';
    oct_to_hex[10] = 'A';
    oct_to_hex[11] = 'B';
    oct_to_hex[12] = 'C';
    oct_to_hex[13] = 'D';
    oct_to_hex[14] = 'E';
    oct_to_hex[15] = 'F';

function asMessage(members)
    local buf = newStringBuilder('conference-members-updated\n');
    for i, member in ipairs(members) do
        local         user = member['user'];
        local   cur_engery = member['cur_engery'];
        local engery_level = member['engery_level'];
        local    is_online = member['is_online'];
        local        is_in = member['is_in'];
        local    can_speak = member['can_speak'];
        local is_moderator = member['is_moderator'];
        
        local flags = 0;

        --  'online';
        if isTrue(is_online) then flags = flags + 8; end;

        -- isInConference;
        if isTrue(is_in) then flags = flags + 4; end;

        -- unmute
        if isTrue(can_speak) then flags = flags + 2; end;

        -- is_moderator
        if isTrue(is_moderator) then flags = flags + 1;end;
      
        buf.append(user).append(';');               -- ID
        buf.append(oct_to_hex[flags]).append(';');  -- flags
        buf.append(cur_engery).append('/').append(engery_level); 
                                                    -- engery

        buf.append('\n');
    end;

    return buf.toString();
end;

function api_dispatch_member_udated (confPhone, timestart)
    local updatedMembers = getConferenceUpdatedMembers(confPhone, timestart);
    local msg = asMessage(updatedMembers);

    local members;
    members = getConferenceMembersIsIn(confPhone);

    local to_users = {};
    for i, member in ipairs(members) do
        local user = member['user'];
        table.insert(to_users, user);
    end;

    batchSendSMS(confPhone, to_users, msg);


    clearConferenceUpdatedMembers(confPhone, updatedMembers);
end;

--  execute if has argv
local confPhone = argv[1];
local timestart = argv[2];
if nil ~= confPhone and nil ~= timestart then
    api_dispatch_member_udated (confPhone, timestart);
end;
