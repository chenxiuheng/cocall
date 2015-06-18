local api = freeswitch.API();
require('libs.commons');
require('libs.db');
require('task.taskService');

local logger = getLogger('task_async_executor');
local tasks = getUnexecutedTask();

for id, cmd in pairs(tasks) do
    clearTimeout(id);
    api:execute('lua', cmd);

    logger.info('executed: ', cmd, ', id = ', id);
end;
