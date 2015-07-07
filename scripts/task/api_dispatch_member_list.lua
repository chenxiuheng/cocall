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



--[[
    一个 UDP 的有效负载为 1460 字节， 一个 FS sip 消息头大约 708 字节，这样算消息有效负载只有 700 字节。 
    一位成员的信息大约需要 30 字节表示，所以每次消息上，只能传输 (700/30)位成员的信息，约 23.3 个。
    为了计算简单，这里只传输 20 人的状态
]]
function api_dispatch_member_list (confPhone, dstUsr)
    local members;
    members = getConferenceMembers(confPhone);

    -- receivers
    local to_users = {};
    if 'all' == dstUsr then
        for i, member in ipairs(members) do
            local is_in = member['is_in'];
            local user = member['user'];
            if isTrue(is_in)  then
                table.insert(to_users, user);
            end;
        end;
    else
        table.insert(to_users, dstUsr);
    end;

    -- interrupted if no receivers
    if 0 == #to_users then
        getLogger("dispatch members").info("no receivers for conference ", confPhone);
        return;        
    end;

    -- 通过分页的方式发送成员列表及状态
    local totalCount = #members; -- 求table长度, 好变态的语法!
    local index = 0;
    local pageNo = 0;
    local pageSize = 20;
    local numPage = math.ceil(totalCount / pageSize);
    while pageNo < numPage do
        index = pageNo * pageSize;

        local buf = newStringBuilder('conference-members\n');
        buf.append(pageNo + 1).append('/').append(numPage).append('/').append(totalCount).append('\n');
        while index < (pageNo + 1) * pageSize and index < totalCount do
            local member = members[index + 1];

            local         user = member['user'];
            local         name = member['name'];
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
          
            buf.append(user).append(';').append(oct_to_hex[flags]).append(';');
            buf.append('\n');

            index = index + 1;
        end;
        batchSendSMS(confPhone, to_users, buf.toString());

        pageNo = pageNo + 1;
    end;
end;


--  execute if has argv
local confPhone = argv[1];
local dstUsr = argv[2];
if nil ~= confPhone then
    api_dispatch_member_list (confPhone, dstUsr);
end;
