require('libs.db');

--字符串分割函数
--传入字符串和分隔符，返回分割后的table
function string.split(str, delimiter)
    local result = {}

	if str==nil or str=='' or delimiter==nil then
		return result;
	end
	
    for match in (str):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end


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


function getLogger(prefix)
    local log = {};
    local level = 0;


    function output(level, args) 
        local msgs = {};
        
        if nil ~= prefix then
            table.insert(msgs, '[');
            table.insert(msgs, prefix);
            table.insert(msgs, ']');
        end;
        
        for i, arg in ipairs(args) do
            if type(arg) == 'string' or type(arg) == 'number' then
                table.insert(msgs, arg);
            elseif nil == arg then
                -- do nothing
            else
              freeswitch.consoleLog('ERROR', "unsupported "..type(arg));
            end;
        end;
        
        table.insert(msgs, '\n');
        freeswitch.consoleLog(level, table.concat(msgs, ' '));
    end;

    log.debug = function(...)
        output('DEBUG', {...});
    end;

    log.info = function(...)
        output('INFO', {...});
    end;

    log.notice = function(...)
        output('NOTICE', {...});
    end;

     log.warn = function(...)
        output('WARNING', {...});
    end;

    return log;
end;


function batchSendSMS(from_user, toUsers, ...)
    local buf;
    local logger = getLogger('batchSendSMS');

    -- msg
    local msg = "";
    buf = newStringBuilder();
    for index, arg in ipairs({...}) do
        if index ~= 1 then 
            buf.append('\n').append(arg);
        else
            buf.append(arg);
        end;
    end;
    msg = buf.toString();

    -- select regist info 
    local sql;
    local hasReceivers = false;

    buf = newSqlBuilder("SELECT distinct user_id, realm, profile from t_registration_ext where user_id in ");
    buf.append('(');
    for index, to in ipairs(toUsers) do
        if index ~= 1 then 
            buf.append(",'").append(to).append("'");
        else
            buf.append("'").append(to).append("'");
        end;
        hasReceivers = true;
    end;
    buf.append(')');
    sql = buf.toString();

    -- interrupted if no receivers
    if not hasReceivers then 
        logger.info(from_user, 'send to nobody online, ', msg);
        return false; 
    end;

    -- send it
    logger.info(sql);
    local hasSentIt = false;
    local from_proto = 'sip';
    local to_proto = 'sip';
    local sip_port = freeswitch.getGlobalVariable('internal_sip_port');
    executeQuery(sql, function(row)
        local to_user = row['user_id'];
        local profile = row['profile'];
        local from = newStringBuilder()
                        .append(from_user)
                        .append('@')
                        .append(row['realm']).toString();
        local from_full = newStringBuilder("sip:")
                            .append(from_user)
                            .append('@').append(row['realm'])
                            .append(':')
                            .append(sip_port).toString();
        local to = newStringBuilder()
                        .append(to_user)
                        .append('@')
                        .append(row['realm']).toString();

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

        logger.debug(from_full, '-->', to, '\n', msg);
    end);

    logger.info('user[', from_user, '] finish send ', msg);

    return hasSentIt;
end;

function sendSMS(from_user, to_user, ...)
    local buf;
    local logger = getLogger('sendSMS');

    -- msg
    local msg = "";
    buf = newStringBuilder();
    for index, arg in ipairs({...}) do
        if index ~= 1 then 
            buf.append('\n').append(arg);
        else
            buf.append(arg);
        end;
    end;
    msg = buf.toString();

    -- select regist info 
    local sql;
    buf = newSqlBuilder("SELECT distinct user_id, realm, profile from t_registration_ext where user_id = ");
    buf.format("'%s'", to_user);
    sql = buf.toString();
    logger.info(sql);


    -- send it
    local hasSentIt = false;
    local from_proto = 'sip';
    local to_proto = 'sip';
    local sip_port = freeswitch.getGlobalVariable('internal_sip_port');
    executeQuery(sql, function(row)
        local to_user = row['user_id'];
        local profile = row['profile'];
        local from = newStringBuilder()
                        .append(from_user)
                        .append('@')
                        .append(row['realm']).toString();
        local from_full = newStringBuilder("sip:")
                            .append(from_user)
                            .append('@').append(row['realm'])
                            .append(':')
                            .append(sip_port).toString();
        local to = newStringBuilder()
                        .append(to_user)
                        .append('@')
                        .append(row['realm']).toString();

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

        logger.debug(from_full, '-->', to, '\n', msg);
    end);

    logger.info('user[', from_user, '] finish send ', msg);

    return hasSentIt;
end;

function newStringBuilder(initString)
    local chars = {};
    local self = {};

    self.append = function (arg)
        if nil == arg then arg = '' end;

        table.insert(chars, arg);

        return self;
    end;

    self.toString = function()
        return table.concat(chars);
    end;


    if nil ~= initString then
        self.append(initString);
    end;

    return self;
end;
