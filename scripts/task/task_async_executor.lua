local api = freeswitch.API();
require('libs.commons');
require('libs.db');
require('task.taskService');

local logger = getLogger('task_async_executor');
local tasks = getExecuteTasks();

for index, task in pairs(tasks) do
    local id        = task['id'];
    local cmd       = task['cmd'];
    local timeout   = task['timeout'];
    local task_type = task['type'];

    if task_type =='timeout' then
        clearTimeout(id);
    else
        recycleInterval(id, timeout); 
    end;

    api:execute('lua', cmd);

end;
