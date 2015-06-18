local api = freeswitch.API();
require('libs.commons');
require('libs.db');
require('task.taskService');

local tasks = getUnexecutedTask();
for id, cmd in ipairs(tasks) do
    api:execute('lua', task);
    clearTimeout(id);
end;
