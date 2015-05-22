function isTrue(value) 
    if (nil == value or '' == value) then return false; end;
    if (2 == value or '2' == value) then  return false; end;
    if (false == value or 'false' == value) then  return false; end;

    return true;
end;

function isFalse(value) 
    if isTrue(value) then return false end;

    return true;
end;

function boolean (value)
    if 1 == value then return true end;
    
    return false;
end;



function debug(k, v) 
    if not v then v = '[NIL]' end;
    freeswitch.consoleLog("DEBUG", k..'='..v..'\n');
end;
function log(k, v)
   if not v then v = '[NIL]' end;
   freeswitch.consoleLog("NOTICE", k..'='..v..'\n');
end;
function error(k, v)
   if not v then v = '[NIL]' end;
   freeswitch.consoleLog("WARNING", k..'='..v..'\n');
end;

function getLogger(prefix)
    local log = {};
    local level = 0;

    function asMsg(arg0, arg1, arg2, arg3, arg4, arg5) 
        local msg = '';
        if nil ~= arg5 then
            msg = string.format("%s %s %s %s %s %s", arg0, arg1, arg2, arg3, arg4, arg5);
        elseif nil ~= arg4 then
            msg = string.format("%s %s %s %s %s", arg0, arg1, arg2, arg3, arg4);
        elseif nil ~= arg3 then
            msg = string.format("%s %s %s %s", arg0, arg1, arg2, arg3);
        elseif nil ~= arg2 then
            msg = string.format("%s %s %s", arg0, arg1, arg2);
        elseif nil ~= arg1 then
            msg = string.format("%s %s", arg0, arg1);
        elseif nil ~= arg0 then
            msg = string.format("%s", arg0);
        else 
            msg = 'nil';
        end;

        return msg;
    end;    

    function output(level, arg0, arg1, arg2, arg3, arg4, arg5) 
        if nil == prefix then
            print('['..level..'] '..asMsg(arg0, arg1, arg2, arg3, arg4, arg5));
        else
            print(prefix..'['..level..'] '..asMsg(arg0, arg1, arg2, arg3, arg4, arg5));
        end;    
    end;

    log.debug = function(arg0, arg1, arg2, arg3, arg4, arg5)
        output('debug', arg0, arg1, arg2, arg3, arg4, arg5);
    end;

    log.info = function(arg0, arg1, arg2, arg3, arg4, arg5)
        output('info', arg0, arg1, arg2, arg3, arg4, arg5);
    end;

     log.warn = function(arg0, arg1, arg2, arg3, arg4, arg5)
        output('warn', arg0, arg1, arg2, arg3, arg4, arg5);
    end;

    return log;
end;



function sendSMS(fromUrl, toUrl, arg0, arg1, arg2, arg3, arg4, arg5)
    local msg;
    local endArgs = false;

    if nil == arg0 then msg ='\n';
    elseif nil == arg1 then msg = string.format('%s\n', arg0); 
    elseif nil == arg2 then msg = string.format('%s\n%s\n', arg0, arg1);
    elseif nil == arg3 then msg = string.format('%s\n%s\n%s\n', arg0, arg1, arg2);
    elseif nil == arg4 then msg = string.format('%s\n%s\n%s\n%s\n', arg0, arg1, arg2, arg3);
    elseif nil == arg5 then msg = string.format('%s\n%s\n%s\n%s\ns\n', arg0, arg1, arg2, arg3, arg4);
    elseif nil ~= arg5 then msg = string.format('%s\n%s\n%s\n%s\ns\ns\n', arg0, arg1, arg2, arg3, arg4, arg5);
    end;


    -- decode sip url
    function readUrl(url, defaultHost)
        local proto = 'sip';
        local user_name;
        local user;
        local user_full;

        --  sip:122@chenxh.thunisoft.com
        for v1, v2, v3 in string.gmatch(url, "([^:]+):([^@]+)@([^;]+)(.*)") do
            proto = v1;
            user_name = v2;
            user = v2..'@'..v3;
            user_full = url;

            return proto, user_name, user, user_full;
        end;

        --  122@chenxh.thunisoft.com
        for v2, v3 in string.gmatch(url, "([^@]+)@([^;]+)(.*)") do
            user_name = v2;
            user = v2..'@'..v3;
            user_full = 'sip:'..v2..'@'..v3;
            return proto, user_name, user, user_full;
        end;

        --  122@
        for v2 in string.gmatch(url, "([^@]+)@") do
            user_name = v2;
            user = v2..'@'..defaultHost;
            user_full = 'sip:'..v2..'@'..defaultHost;
            return proto, user_name, user, user_full;
        end;

        --  122        
        local v2 = url;
        user_name = v2;
        user = v2..'@'..defaultHost;
        user_full = 'sip:'..v2..'@'..defaultHost;
        return proto, user_name, user, user_full;
    end;


    local hostname = freeswitch.API():execute("global_getvar", "global_hostname");
    if nil == hostname or '' == hostname then
        hostname = '0.0.0.0';
        print('global_hostname in vars.xml is unknown');
    end;

    local from_proto, from_user, from, from_full = readUrl(fromUrl, hostname);
    local to_proto, to_user, to, to_full = readUrl(toUrl, '0.0.0.0');


    local hasSentIt = false;
    local sql;
    sql = string.format("SELECT reg_user as user, realm as realm from registrations where reg_user='%s'", to_user);
    executeQuery(sql, function(row)
        local event = freeswitch.Event("CUSTOM", "SMS::SEND_MESSAGE");
        event:addHeader("proto", from_proto);
        event:addHeader("dest_proto", to_proto);
        event:addHeader("from", from);
        event:addHeader("from_user", from_user);
        event:addHeader("from_full", from_full); 
        event:addHeader("to", row['user']..'@'..row['realm']);
        event:addHeader("to_user", row['user']);
        event:addHeader("type", "text/plain");
        event:addHeader("replying", "false");
        event:addHeader("sip_profile", "internal"); -- sofia status profile internal reg

        event:addBody(msg);
        event:chat_execute("send");
        hasSentIt = true;
    end);

    return hasSentIt;
end;
