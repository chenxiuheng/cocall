local api = freeswitch.API();
local scripts_base_dir = api:execute("global_getvar", "base_dir")..'/scripts';
if nil == string.find(package.path, scripts_base_dir) then
    package.path = package.path..';'..
                scripts_base_dir..'/?.lua'..';';
end;



require('libs.db');
require('user.userService');

print(event:serialize());
local event = freeswitch.Event("CUSTOM", "SMS::SEND_MESSAGE");
        event:addHeader("proto", "sip");
        event:addHeader("dest_proto", "sip");
        event:addHeader('from', '1017');
        event:addHeader('from_user', '3401');
        event:addHeader('from_full', 'sip:3401@0.0.0.0');
        event:addHeader("type", "text/plain");
        event:addHeader("replying", "false");
        event:addHeader("sip_profile", "internal");

        local to = '1022@0.0.0.0';
        local to_user = '1022';
        event:addHeader("to", to);
        event:addHeader("to_user", to_user);



        event:addBody("hello");
        event:chat_execute("send");
