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
A.api_send_conferences = function (from_user, to_user)
    local cmd = newStringBuilder("task/api_send_conferences.lua");
    cmd.append(" ").append(from_user);
    cmd.append(" ").append(to_user);

    execute(cmd.toString());
end;

A.api_dispatch_member_list = function (confPhone)
    local cmd = newStringBuilder("task/api_dispatch_member_list.lua");
    cmd.append(" ").append(confPhone);

    execute(cmd.toString());
end;

A.api_dispatch_member_energy = function (confPhone)
    local cmd = newStringBuilder("task/api_dispatch_member_energy.lua");
    cmd.append(" ").append(confPhone);

    execute(cmd.toString());
end;

A.api_clear_registrationExt = function()
   -- don't clear
   -- deleteRegistrationExtOutOfDate();
end;
-- // end

local logger = getLogger('task_async_executor');
local tasks = getExecuteTasks();

local func;
for index, task in pairs(tasks) do
    local id        = task['id'];
    local cmd       = task['cmd'];
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
        func(args[1], args[2], args[3], args[4]);
    else
        logger.error('unknown cmd ', cmd);
    end;
end;
