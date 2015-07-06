require('conference.conferenceService');

local log = getLogger("dispatch_member_removed");

function add (confPhone, userId)
    local selected = getConferenceMembers(confPhone, userId);
    if #selected == 0 then
        log.info(userId, "removed from conferece[", confPhone, "] again");
        return;
    end;

    local members = getConferenceMembersIsIn(confPhone);
    local to_users = {};
    for i, member in ipairs (members) do
        table.insert(to_users, member['user']);
    end;

    local name = selected[0]['name'];
    local buf = newStringBuilder('conference_member_add\n');
    buf.append(userId).append(";").append(name).append("\n");
    batchSendSMS(confPhone, to_users, buf.toString());
end;

function removed (confPhone, userId)
    local selected = getConferenceMembers(confPhone, userId);
    if #selected > 0 then
        log.info(userId, "add into conferece[", confPhone, "] again");
        return;
    end;

    local members = getConferenceMembersIsIn(confPhone);
    local to_users = {};
    for i, member in ipairs (members) do
        table.insert(to_users, member['user']);
    end;

    local buf = newStringBuilder('conference_member_removed\n');
    buf.append(userId).append(";").append("\n");
    batchSendSMS(confPhone, to_users, buf.toString());
end;

--  execute if has argv
local confPhone = argv[1];
local userId = argv[2];
local func = argv[3];
if nil ~= confPhone and nil ~= userId then
    if func == 'add' then
      add(confPhone, userId);
    elseif func =='removed' then
      removed(confPhone, userId);
    else
      getLogger().warn("illegal args ", confPhone, userId, func);
    end;
end;
