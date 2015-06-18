
require('libs.db');
require('libs.commons');
require('conference.conferenceService');
require('user.userService');


local logger = getLogger('onStartup');
local sql;
sql = string.format('update t_conference_member set n_is_in=2 where n_is_in<>2');
executeUpdate(sql);

sql = string.format('update t_conference set n_is_running=2 where n_is_running<>2');
executeUpdate(sql);


sql = string.format('delete from t_registration_ext');
executeUpdate(sql);
logger.warn('clear DB');

local last_clock = now();
local cur_clock = last_clock;

local clock_rate = 97;
local last_clock_user   = cur_clock;
local last_clock_conf   = cur_clock;
local last_clock_energy = cur_clock;
while true do
    local cur_clock = now();
    if nil == cur_clock then
        logger.error('db service is disabled, stop loop');
        break;
    end;

    -- wait for CPU time
    logger.debug('now:', cur_clock, "diff:", (cur_clock - last_clock), "(ms).");
    if (cur_clock - last_clock < clock_rate) then
      freeswitch.msleep(clock_rate - (cur_clock - last_clock));
    end;
    cur_clock = now(); -- new clock after sleep
    if nil == cur_clock then
        logger.error('db service is disabled, stop loop');
        break;
    end;
    last_clock = cur_clock;

    -- do jobs
    if (cur_clock - last_clock_user)  > (60 * 1000) then
        last_clock_user   = cur_clock;
        freeswitch.API():execute('luarun', "user/task.lua");
    end;

    if (cur_clock - last_clock_conf) > 1300 then
        last_clock_conf   = cur_clock;
        freeswitch.API():execute('luarun', "conference/task_member_list.lua");
    end;

    if (cur_clock - last_clock_energy) > 500 then
        last_clock_energy = cur_clock;
        freeswitch.API():execute('luarun', "conference/task_member_energy.lua");
    end;

    -- the last is synch
    freeswitch.API():execute('lua', "task/task_async_executor.lua");
end;

