require('task.taskService');

-- ///////////////////////////////////////////////
--   API define(s)
-- ///////////////////////////////////////////////
local thread_max = 32;
local thread_remains = thread_max;
function execute(cmd)
    thread_remains = thread_remains - 1;

    if (thread_remains < 0) then
        thread_remains = thread_max;
        freeswitch.API():execute('lua', cmd);
    else
        -- async execute
        freeswitch.API():execute('luarun', cmd);
    end;
end;

local A = {};
A.api_send_conferences = function (created, from_user, to_user)
    local cmd = newStringBuilder("task/api_send_conferences.lua");
    cmd.append(" ").append(from_user);
    cmd.append(" ").append(to_user);

    execute(cmd.toString());
end;

A.api_dispatch_member_list = function (created, confPhone, dst)
    local cmd = newStringBuilder("task/api_dispatch_member_list.lua");
    cmd.append(" ").append(confPhone);
    cmd.append(" ").append(dst);

    execute(cmd.toString());
end;

A.member_updated = function (created, confPhone)
    local cmd = newStringBuilder("task/api_dispatch_member_updated.lua");
    cmd.append(" ").append(confPhone);
    cmd.append(" '").append(created).append("'");

    execute(cmd.toString());
end;

A.member_removed = function(created, confPhone, userId, func)
    local cmd = newStringBuilder("task/api_dispatch_member_removed.lua");
    cmd.append(" ").append(confPhone);
    cmd.append(" ").append(userId);
    cmd.append(" ").append(func);

    execute(cmd.toString());
end;

A.api_clear_registrationExt = function(created)
    -- freeswitch.API():execute('lua', "task/api_clear_registrationExt.lua"); -- must synch
end;

A.api_clear_executed_timeout = function(created)
    freeswitch.API():execute('lua', "task/api_clear_executed_timeout.lua"); -- must synch
end;

A.api_clear_invalid_conferences = function(created)
    freeswitch.API():execute('lua', "task/api_clear_invalid_conferences.lua"); -- must synch
end;
-- // end

local logger = getLogger('task_async_executor');
local tasks = getExecuteTasks();

local func;
for index, task in pairs(tasks) do
    local id        = task['id'];
    local cmd       = task['cmd'];
    local created   = task['created'];
    local timeout   = task['timeout'];
    local task_type = task['type'];
    local args      = task['args'];

    -- clear task
    if task_type =='timeout' then
        clearTimeout(id);
    else
        recycleInterval(id, timeout); 
    end;

    -- invoke
    func = A[cmd];
    if (nil ~= func) then
        func(created, args[1], args[2], args[3], args[4]);
    else
        logger.error('unknown cmd ', cmd);
    end;
end;
