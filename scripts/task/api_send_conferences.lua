require('conference.conferenceService');

function api_send_conferences (from_user, to_user)
    local conferences = getMyConferences(to_user);

    local totalCount = #conferences; -- 求table长度, 好变态的语法!
    if 0 == totalCount then
        sendSMS(from_user, to_user, 'conference-list\n');
        return;        
    end;

    local index = 0;
    local pageNo = 0;
    local pageSize = 6;
    local numPage = math.ceil(totalCount / pageSize);
    while pageNo < numPage do
        index = pageNo * pageSize;

        local buf = newStringBuilder('conference-list\n');
        buf.append(pageNo + 1).append('/').append(numPage).append('/').append(totalCount).append('\n');
        while index < (pageNo + 1) * pageSize and index < totalCount do
            local info = conferences[index + 1];
            buf.append(info['conference']).append(';');
            buf.append(info['name']).append(';');
            buf.append(info['creator']).append(';');
            buf.append(info['creator_name']).append(';');
            buf.append(info['created']).append(';');
            buf.append(info['num_is_in']).append('/').append(info['num_member']).append(';');
            buf.append('\n');

            index = index + 1;
        end;
        sendSMS(from_user, to_user, buf.toString());

        pageNo = pageNo + 1;
    end;
end;

--  execute if has argv
local from_user = argv[1];
local to_user = argv[2];
if nil ~= from_user and nil ~= to_user then
    api_send_conferences(from_user, to_user);
end;
