local api = freeswitch.API();
FreeSWITCH_IPv4 = message:getHeader('FreeSWITCH-IPv4');


require('libs.db');
require('libs.commons');
require('conference.conferenceService');
require('task.taskService');

-- ============================ accept ACTION(s) ================================ --



local action = "nil";
local params = "";
local user = message:getHeader('from_user');
local from_user = message:getHeader('from_user');
local to_user = message:getHeader('to_user');
local user_name = message:getHeader('user_name');
local user_id = message:getHeader('user_id');
local body = string.gsub(message:getBody()..'\n', '<br>', '\n');
local logger = getLogger('conference.110');
logger.info(body);

if nil == user_id then user_id = user end;
if nil == user then
    error('Unknown user_id from message header, it will cause confusion between freeswitch and app system ');
   
    message:chat_execute('reply', 'ERROR:Unknown user_id from message header, it will cause confusion between freeswitch and app system');
end;


local i = string.find(body, '\n');
if nil == i then
     message:chat_execute('reply', 'illegal args:['.. body .. ']');
end;

if nil ~= i then
    action = string.sub(body, 0, i-1);
    params = string.sub(body, i+1);

    local service;  -- conference service

    --- 1, create conference
    if 'create_conference' == action then

        local phoneNo;

        local fastInsert = true;
        local rowIndex = 1;
        for v2, v3 in string.gmatch(params, "([^;\n]*)[;]?([^\n]*)\n") do

            if 1 == rowIndex then 
                local conf_name = v2;
                local creator_name = v3; -- creator

                phoneNo = createConference(conf_name, from_user, creator_name);
                service = newConferenceService(phoneNo);

                sendSMS(to_user, from_user, "conference-created", service.toSimpleString());
            elseif nil ~= service and nil~= v2 and nil ~= v3 then 
                local member = {};
                member['user'] = v2;
                member['name'] = v3;
                service.addMember(member, fastInsert);
                sendSMS(phoneNo, v2, "conference-join", service.toSimpleString());
            end;

            rowIndex = rowIndex + 1;
        end

        if nil ~= service and nil ~= phoneNo then
            service.setModerator(user);
        end;

    --- 2, get my conferences
    elseif 'list_conferences' == action then
        local pageNo, pageSize;

        if nil ~= params then
            for v1, v2 in string.gmatch(params, "([%d]*)/([%d]*)(.*)") do
               pageNo = v1;
               pageSize = v2;
            end; 
        end;
        if nil == pageNo or nil == pageSize then
            pageNo = 1;
            pageSize = 6;
        end;
        
        local cmd = string.format("api_send_conferences %s %s %s %s", to_user, from_user, pageNo, pageSize);
        setTimeout(cmd, 500); -- 500ms later to send, avoid send msg frequently
    else 
        sendSMS(to_user, from_user, 'error', "I don't know what you said");
    end;


   if nil ~= service then
        service.notifyAll();
  end;
end;

