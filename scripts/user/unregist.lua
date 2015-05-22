local api = freeswitch.API();
local scripts_base_dir = api:execute("global_getvar", "base_dir")..'/scripts';
if nil == string.find(package.path, scripts_base_dir) then
    package.path = package.path..';'..
                scripts_base_dir..'/?.lua'..';';
end;
require('libs.db');
require('libs.commons');
require('user.userService');

local from_user = event:getHeader("from-user");
local call_id = event:getHeader("call-id");


if nil ~= from_user and nil ~= call_id then
    userLogout(from_user, call_id);
end;
