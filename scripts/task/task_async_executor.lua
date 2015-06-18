local api = freeswitch.API();
require('libs.commons');
require('libs.db');
require('task.taskService');

local logger = getLogger('task_async_executor');
local tasks = getUnexecutedTask();

for id, cmd in pairs(tasks) do
    api:execute('lua', cmd);
    clearTimeout(id);
end;
