
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
        local msg = '\n';
        if nil ~= arg5 then
            msg = string.format("%s %s %s %s %s %s\n", arg0, arg1, arg2, arg3, arg4, arg5);
        elseif nil ~= arg4 then
            msg = string.format("%s %s %s %s %s\n", arg0, arg1, arg2, arg3, arg4);
        elseif nil ~= arg3 then
            msg = string.format("%s %s %s %s\n", arg0, arg1, arg2, arg3);
        elseif nil ~= arg2 then
            msg = string.format("%s %s %s\n", arg0, arg1, arg2);
        elseif nil ~= arg1 then
            msg = string.format("%s %s\n", arg0, arg1);
        elseif nil ~= arg0 then
            msg = string.format("%s\n", arg0);
        else 
            msg = 'nil\n';
        end;

        return msg;
    end;    

    function output(level, arg0, arg1, arg2, arg3, arg4, arg5) 
        if nil ~= prefix then
            freeswitch.consoleLog('debug', prefix..'\n');
        end;

        freeswitch.consoleLog(level, asMsg(arg0, arg1, arg2, arg3, arg4, arg5));
    end;

    log.debug = function(arg0, arg1, arg2, arg3, arg4, arg5)
        output('DEBUG', arg0, arg1, arg2, arg3, arg4, arg5);
    end;

    log.info = function(arg0, arg1, arg2, arg3, arg4, arg5)
        output('INFO', arg0, arg1, arg2, arg3, arg4, arg5);
    end;

     log.warn = function(arg0, arg1, arg2, arg3, arg4, arg5)
        output('WARNING', arg0, arg1, arg2, arg3, arg4, arg5);
    end;

    return log;
end;


function batchSendSMS(from_user, toUsers, ...)
    local args = {...};

    -- msg
    local msg = "";
    for index, arg in ipairs(args) do
        if index ~= 1 then 
            msg = msg .."\n".. arg;
        else
            msg = arg;
        end;
    end;

    -- sql
    local sql;
    local hasReceivers = false;
    sql = "SELECT distinct user_id, realm, profile from t_registration_ext where user_id in ";
    sql = sql ..'(';
    for index, to in ipairs(toUsers) do
        if index ~= 1 then 
            sql = sql ..",'".. to .."'";
        else
            sql = sql .."'".. to .."'";
        end;
        hasReceivers = true;
    end;
    sql = sql ..')';

    -- interrupted if no receivers
    if not hasReceivers then return false; end;

    -- send it
    local hasSentIt = false;
    local from_proto = 'sip';
    local to_proto = 'sip';
    local sip_port = freeswitch.getGlobalVariable('internal_sip_port');
    executeQuery(sql, function(row)
        local from = string.format("%s@%s", from_user, row['realm']);
        local from_full = string.format('sip:%s@%s:%s', from_user, row['realm'], sip_port);
        local to_user = row['user_id'];
        local to = string.format("%s@%s", to_user, row['realm']);
        local profile = row['profile'];

        local event = freeswitch.Event("CUSTOM", "SMS::SEND_MESSAGE");
        event:addHeader("proto",      from_proto);
        event:addHeader("dest_proto", to_proto);
        event:addHeader("from",       from);
        event:addHeader("from_user",  from_user);
        event:addHeader("from_full",  from_full); 
        event:addHeader("to",         to);
        event:addHeader("to_user",    to_user);
        event:addHeader("sip_profile", profile); -- sofia status profile internal reg
        event:addHeader("type", "text/plain");
        event:addHeader("replying", "false");


        event:addBody(msg);
        event:chat_execute("send");
        hasSentIt = true;

        local logger = getLogger('com.thunisoft.cocall.sms');
        logger.debug(from_full, '-->', to, '\n', msg);

    end);

    return hasSentIt;
end;

function sendSMS(fromUrl, toUrl, arg0, arg1, arg2, arg3, arg4, arg5)
    function v (arg)
        if nil == arg then return ''; else return arg; end;
    end;

    local msg;
    local endArgs = false;

    if     nil ~= arg5 then msg = string.format('%s\n%s\n%s\n%s\ns\ns\n', v(arg0), v(arg1), v(arg2), v(arg3), v(arg4), v(arg5));
    elseif nil ~= arg4 then msg = string.format('%s\n%s\n%s\n%s\ns\n',    v(arg0), v(arg1), v(arg2), v(arg3), v(arg4));
    elseif nil ~= arg3 then msg = string.format('%s\n%s\n%s\n%s\n',       v(arg0), v(arg1), v(arg2), v(arg3));
    elseif nil ~= arg2 then msg = string.format('%s\n%s\n%s\n',           v(arg0), v(arg1), v(arg2));
    elseif nil ~= arg1 then msg = string.format('%s\n%s\n',               v(arg0), v(arg1));
    elseif nil ~= arg0 then msg = string.format('%s\n',                   v(arg0));
    else msg ='\n';
    end;


    -- decode sip url
    local hostname = freeswitch.API():execute("global_getvar", "global_hostname");
    if nil == hostname or '' == hostname then
        hostname = '0.0.0.0';
        print('global_hostname in vars.xml is unknown');
    end;
    local sip_port = freeswitch.getGlobalVariable('internal_sip_port');
    function readUrl(url, defaultHost)
        local proto = 'sip';
        local user_name;
        local user;
        local user_full;

        --  sip:122@chenxh.thunisoft.com:9060
        for v1, v2, v3, v4 in string.gmatch(url, "([^:]+):([^@]+)@([^:]+):([^;]+)(.*)") do
            proto = v1;
            user_name = v2;
            user = v2..'@'..v3;
            user_full = v1 ..':'..v2..'@'..v3..':'..v4;

            return proto, user_name, user, user_full;
        end;

        --  sip:122@chenxh.thunisoft.com
        for v1, v2, v3 in string.gmatch(url, "([^:]+):([^@]+)@([^;]+)(.*)") do
            proto = v1;
            user_name = v2;
            user = v2..'@'..v3;
            user_full = v1 ..':'..v2..'@'..v3..':'..sip_port;

            return proto, user_name, user, user_full;
        end;

        --  122@chenxh.thunisoft.com
        for v2, v3 in string.gmatch(url, "([^@]+)@([^;]+)(.*)") do
            user_name = v2;
            user = v2..'@'..v3;
            user_full = 'sip:'..v2..'@'..v3..':'..sip_port;
            return proto, user_name, user, user_full;
        end;

        --  122@
        for v2 in string.gmatch(url, "([^@]+)@") do
            user_name = v2;
            user = v2..'@'..defaultHost;
            user_full = 'sip:'..v2..'@'..defaultHost..':'..sip_port;
            return proto, user_name, user, user_full;
        end;

        --  122        
        local v2 = url;
        user_name = v2;
        user = v2..'@'..defaultHost;
        user_full = 'sip:'..v2..'@'..defaultHost..':'..sip_port;
        return proto, user_name, user, user_full;
    end;



    local from_proto, from_user, from = readUrl(fromUrl, hostname);
    local to_proto, to_user, to, to_full = readUrl(toUrl, '0.0.0.0');


    local hasSentIt = false;
    local sql;
    sql = string.format("SELECT distinct user_id, realm, profile from t_registration_ext where user_id='%s'", to_user);
    executeQuery(sql, function(row)
        local event = freeswitch.Event("CUSTOM", "SMS::SEND_MESSAGE");
        event:addHeader("proto",      from_proto);
        event:addHeader("dest_proto", to_proto);
        event:addHeader("from",       from);
        event:addHeader("from_user",  from_user);
        event:addHeader("from_full",  string.format('sip:%s@%s:%s', from_user, row['realm'], sip_port)); 
        event:addHeader("to",         string.format('%s@%s', row['user_id'], row['realm']));
        event:addHeader("to_user",    row['user_id']);
        event:addHeader("type", "text/plain");
        event:addHeader("replying", "false");
        event:addHeader("sip_profile", row['profile']); -- sofia status profile internal reg


        event:addBody(msg);
        event:chat_execute("send");
        hasSentIt = true;

        local logger = getLogger('com.thunisoft.cocall.sms');
        logger.debug('sendTo', row['user_id'], '@', row['realm']);
        logger.debug(msg);
    end);

    return hasSentIt;
end;
