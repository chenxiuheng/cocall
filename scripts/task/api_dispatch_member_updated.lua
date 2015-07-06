require('conference.conferenceService');


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

function api_dispatch_member_energy (confPhone, timestart)
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
end;

--  execute if has argv
local confPhone = argv[1];
local timestart = argv[2];
if nil ~= confPhone and nil ~= timestart then
    api_dispatch_member_energy (confPhone, timestart);
end;
