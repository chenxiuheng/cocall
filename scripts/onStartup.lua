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


print('prepare delete online user out of date');
while true do
    deleteRegistrationExtOutOfDate();

    freeswitch.msleep(60 * 1000);
end;

