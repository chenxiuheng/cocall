require('conference.conferenceService');

function api_send_conferences (from_user, to_user, page_no, page_size)
    local total_count = countMyConferences(to_user, false);
    if 0 == total_count or  page_size <= 0 then
        sendSMS(from_user, to_user, 'conference-list\n');
        return;        
    end;

    local num_page = math.ceil(total_count / page_size);
    if num_page < page_no then
        page_no = 1;
    end;
    local conferences = getMyConferences(to_user, false, page_no, page_size);
    local buf = newStringBuilder('conference-list\n');
    buf.append(page_no).append('/').append(num_page).append('/').append(total_count).append('\n');
    for i, info in ipairs(conferences) do
        buf.append(info['conference']).append(';');
        buf.append(info['name']).append(';');
        buf.append(info['creator']).append(';');
        buf.append(info['creator_name']).append(';');
        buf.append(info['created']).append(';');
        buf.append(info['num_is_in']).append('/').append(info['num_member']).append(';');
        buf.append('\n');
    end;
    sendSMS(from_user, to_user, buf.toString());
end;

--  execute if has argv
local from_user = argv[1];
local to_user = argv[2];
local page_no;
local page_size;
if nil == argv[3] or nil == argv[4] then
    page_no = 1;
    page_size = 6;
else
    page_no = tonumber(argv[3]);
    page_size = tonumber(argv[4]);
end;

if nil ~= from_user and nil ~= to_user then
    api_send_conferences(from_user, to_user, page_no, page_size);
end;
