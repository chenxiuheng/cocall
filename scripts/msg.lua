    function readUrl(url)
        local proto = 'sip';
        local user_name;
        local user;
        local user_full;

        --  sip:122@chenxh.thunisoft.com
        for v1, v2, v3 in string.gmatch(url, "([^:]+):([^@]+)@([^;]*)(.*)") do
            proto = v1;
            user_name = v2;
            user = v2..'@'..v3;
            user_full = url;

            return proto, user_name, user, user_full;
        end;

        --  122@chenxh.thunisoft.com
        for v2, v3 in string.gmatch(url, "([^@]+)@([^;]*)(.*)") do
            user_name = v2;
            user = v2..'@'..v3;
            user_full = 'sip:'..v2..'@'..v3;
            return proto, user_name, user, user_full;
        end;

        --  122        
        local v2 = url;
        user_name = v2;
        user = v2..'@0.0.0.0';
        user_full = 'sip:'..v2..'@0.0.0.0';
        return proto, user_name, user, user_full;
    end;

local proto, from_user, user_full = readUrl('sip:123@172.156.s.1');
print(proto, from_user, user_full);

print(readUrl('sip:123@172.156.s.1'));
print(readUrl('1234@172.156.s.3'));
print(readUrl('123'));

freeswitch.API():execute('conference', '340000693 dial user/2017');

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

