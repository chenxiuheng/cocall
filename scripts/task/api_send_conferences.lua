require('conference.conferenceService');

function api_send_conferences (from_user, to_user)
    local conferences = getMyConferences(to_user);

    local buf = newStringBuilder('conference-list');
    for i, info in ipairs(conferences) do
        buf.append('\n');

        buf.append(info['conference']).append(';');
        buf.append(info['name']).append(';');
        buf.append(info['creator']).append(';');
        buf.append(info['creator_name']).append(';');
        buf.append(info['age']).append(';');
        buf.append(info['num_is_in']).append('/').append(info['num_member']).append(';');
    end;
    buf.append('\n');

    sendSMS(from_user, to_user, buf.toString());
end;

--  execute if has argv
local from_user = argv[1];
local to_user = argv[2];
if nil ~= from_user and nil ~= to_user then
    api_send_conferences(from_user, to_user);
end;
