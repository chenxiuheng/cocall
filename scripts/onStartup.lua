local api = freeswitch.API();
local scripts_base_dir = api:execute("global_getvar", "base_dir")..'/scripts';
if nil == string.find(package.path, scripts_base_dir) then
    package.path = package.path..';'..
                scripts_base_dir..'/?.lua'..';';
end;
require('libs.db');
require('libs.commons');
require('conference.conferenceService');


local sql;
sql = string.format('update t_conference_member set n_is_in=2 where n_is_in<>2');
executeUpdate(sql);
print(">>>> update t_conference_member  n_is_in = 2 <<< ");

sql = string.format('update t_conference set n_is_running=2 where n_is_running<>2');
executeUpdate(sql);
print(">>>> update conference  n_is_running = 2 <<< ");


sql = string.format('delete from registrations');
executeUpdate(sql);
print(">>>> delete from registrations");

sql = string.format('update t_user set n_is_online = 2, c_realm = null');
executeUpdate(sql);
print(">>>> set t_user online=2");


print('prepare delete online user out of date');
while true do
    
    -- login at 2 minutis ago, will be delete
    sql = string.format(
        "delete from registrations where reg_user in"..
        " (select c_phone_no from t_user where n_is_online = 1 and d_login < (now() - INTERVAL '61 m'))"
    );
    executeUpdate(sql);

    -- update t_user n_is_online flag
    sql = string.format(
            "update t_user set n_is_online = 2, d_login = null where n_is_online = 1 "..
            " and c_phone_no not in (select reg_user from registrations)"
        );
    executeUpdate(sql);

    freeswitch.msleep(61 * 60 * 1000);
end;

