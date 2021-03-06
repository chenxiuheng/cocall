
require('libs.db');
require('libs.commons');
require('task.taskService');

local logger = getLogger('onStartup');
local sql;
sql = 'update t_conference_member set n_is_in=2, n_has_video=2, n_member_id = null where n_is_in<>2';
executeUpdate(sql);

sql = string.format('update t_conference set n_is_running=2 where n_is_running<>2');
executeUpdate(sql);

sql = string.format('delete from t_registration_ext');
executeUpdate(sql);

setInterval('clear_regist', 'api_clear_registrationExt', 5 * 60 * 1000);
setInterval('clear_timeout', 'api_clear_executed_timeout', 5 * 60 * 1000);
setInterval('clear_conferences', 'api_clear_invalid_conferences', 5 * 60 * 1000);

local last_clock = now();
local clock_rate = 25;
local cur_clock = last_clock;
while nil ~= cur_clock  do
    cur_clock = now();

    -- wait for CPU time
    if (cur_clock - last_clock < clock_rate) then
        local diff = clock_rate - (cur_clock - last_clock);
        logger.debug('now:', cur_clock, "sleep:", diff, "(ms).");

        freeswitch.msleep(diff);
    end;

    last_clock = now();

    -- execute jobs
    freeswitch.API():execute('lua', "task/task_async_executor.lua");
end;

