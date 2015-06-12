local api = freeswitch.API();
local scripts_base_dir = api:execute("global_getvar", "base_dir")..'/scripts';
if nil == string.find(package.path, scripts_base_dir) then
    package.path = package.path..';'..
                scripts_base_dir..'/?.lua'..';';
end;
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

local userClock = 0;
local conferenceClock = 0;
while true do
    freeswitch.msleep(100);

    userClock = userClock + 25;
    conferenceClock = conferenceClock + 25;

    if userClock > (60 * 1000) then
        userClock = 0;
        freeswitch.API():execute('bgapi', "lua user/task.lua");
    end;

    if conferenceClock > 1300 then
        conferenceClock = 0;
        freeswitch.API():execute('bgapi', "lua conference/task.lua");
    end;
end;

