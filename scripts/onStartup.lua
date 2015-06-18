
require('libs.db');
require('libs.commons');
require('conference.conferenceService');
require('user.userService');


local sql;
sql = string.format('update t_conference_member set n_is_in=2 where n_is_in<>2');
executeUpdate(sql);
print(">>>> reset conference member(s)");

sql = string.format('update t_conference set n_is_running=2 where n_is_running<>2');
executeUpdate(sql);
print(">>>> reset conference(s)");


sql = string.format('delete from t_registration_ext');
executeUpdate(sql);
print(">>>> delete from t_registration_ext");


local logger = getLogger('onStartup');
local last_clock = now();
local cur_clock = last_clock;

local clock_rate = 97;
local userClock = 0;
local conferenceClock = 0;
local conferenceEnergyClock = 0;
while nil == cur_clock do
    local cur_clock = now();
    if nil == cur_clock then
        logger.error('db service is disabled, stop loop');
        break;
    end;

    -- wait for CPU time
    if (cur_clock - last_clock < clock_rate) then
      freeswitch.msleep(clock_rate - (cur_clock - last_clock));
    end;
    cur_clock = now(); -- new clock after sleep
    if nil == cur_clock then
        logger.error('db service is disabled, stop loop');
        break;
    end;

    -- do jobs
    userClock             = userClock             + (cur_clock - last_clock);
    conferenceClock       = conferenceClock       + (cur_clock - last_clock);
    conferenceEnergyClock = conferenceEnergyClock + (cur_clock - last_clock);
    last_clock = cur_clock;

    if userClock > (60 * 1000) then
        userClock = 0;
        freeswitch.API():execute('luarun', "user/task.lua");
    end;

    if conferenceClock > 1300 then
        conferenceClock = 0;
        freeswitch.API():execute('luarun', "conference/task_member_list.lua");
    end;

    if conferenceEnergyClock > 500 then
        conferenceEnergyClock = 0;
        freeswitch.API():execute('luarun', "conference/task_member_energy.lua");
    end;

    -- the last is synch
    freeswitch.API():execute('lua', "task/task_async_executor.lua");
end;

