local api = freeswitch.API();

require('libs.db');
require('libs.commons');
require('task.taskService');
require('conference.conferenceService');

local from_user = message:getHeader('from_user');
local confPhone = message:getHeader('to_user');
local body = message:getBody();

-- srvice to deal with action(s)
local service = newConferenceService(confPhone);
local logger = getLogger('msg#'..confPhone);
logger.notice(from_user, '/', confPhone, "said: ", body);

if nil ~= confPhone and nil ~=  from_user then
    local cmd = string.gsub(body..'\n', '<br>', '\n');
    local i = string.find(cmd, '\n');
    local action = string.sub(cmd, 0, i-1);
    local params = string.sub(cmd, i+1);


    if action == 'conference_add_member' then
        local success = true;
        local member = {};
        for user, name in string.gmatch(params..'\n', "([^;\n]*)[;]?([^\n]*)\n") do
            if user ~= '' then
                member['user'] = user;
                member['name'] = name;
                success = service.addMember(member);

                sendSMS(confPhone, user, "conference-join", service.toSimpleString());
            else
                logger.warn('Fail Add User(', user, name, ')');
            end;
        end

        service.notifyAll();
    elseif action == 'conference_leave' then
        service.removeMember(from_user);
        sendSMS(confPhone, user, "conference-left", service.toSimpleString());

        local id =  string.format("member_removed %s %s", confPhone, from_user);
        local cmd = string.format("member_removed %s %s removed", confPhone, from_user);
        setTimeout(id, cmd, 700);

    elseif action == 'conference_kick' then
        for user in string.gmatch(params..'\n', "([^\n]*)\n") do
            if '' ~= user then
                service.removeMember(user);
                sendSMS(confPhone, user, "conference-kicked", service.toSimpleString());

                local id =  string.format("member_removed %s %s", confPhone, user);
                local cmd = string.format("member_removed %s %s removed", confPhone, user);
                setTimeout(id, cmd, 700);
            end;
        end;
    elseif action == 'conference_destroy' then
        service.sayTo("all", from_user, 'conference-kicked');
        service.destroy();

    elseif action == 'conference_mute'  then
        for user in string.gmatch(params, "([^\n]*)\n") do
            if nil ~= user and '' ~= user then
                service.mute(user);
                logger.notice(from_user, 'mute', user);
            end;
        end;

        service.notifyAll();
    elseif action == 'conference_unmute' then
        for user in string.gmatch(params, "([^\n]*)\n") do
            if nil ~= user and '' ~= user then
                service.unmute(user);
                logger.notice(from_user, 'unmute', user);
            end;
        end;

        service.notifyAll();
    elseif action == 'conference_change_video' then
        service.changeVideoFloor(from_user);
    elseif action =='conference_set_moderator' then
        local lastModerator = service.getModerator();

        for user in string.gmatch(params, "([^\n]*)\n") do
            service.setModerator(user);

            -- you are a moderator
            if lastModerator ~= user then
                sendSMS(confPhone, user, "conference-as-moderator", service.toSimpleString());
            end;

            -- you are a member only
            if nil ~= lastModerator and lastModerator ~= user then
                sendSMS(confPhone, lastModerator, "conference-as-member", service.toSimpleString());
            end;
        end;

        service.notifyAll();
    elseif action == 'conference-ask-for-moderator' then
        local members = service.getMembers('moderator', from_user);
        local hasSentIt = false;
        for i, member in ipairs(members) do
           local is_in = member['is_in'];
           local to = member['user'];

           if isTrue(is_in) then
              hasSentIt = sendSMS(confPhone, to, 'conference-ask-for-moderator', params);
           end;
        end;

        if not hasSentIt then
            service.setModerator(from_user);
            sendSMS(confPhone, from_user, "conference-as-moderator", service.toSimpleString());
        end;

        service.notifyAll();
    elseif action == 'conference_get_members' then
        service.getMemberStates(user);
    elseif action == 'conference_set_name' then
        for new_name in string.gmatch(params, "([^\n]*)\n") do
            if nil ~= new_name and "" ~= new_name then
                service.setName(new_name);
            end;
        end;
        service.sayTo('all', nil, 'conference-set-name',  service.getName());
    else -- say msg to others
        local sentIt = false;


        local txt = params;
        local i = string.find(action, ':');
        if nil ~= i then
            local sayTo = string.sub(action, 0, i-1);
            local dstUsers = string.sub(action, i+1);

            if sayTo == 'sayTo' then
                sentIt = true;
                service.sayTo(dstUsers, nil, txt);
            end;
        end;

        if not sentIt then
            service.sayTo('all', nil, txt);
        end;

    end;

else
    logger.warn("illegal arguments from ", from_user, "to", confPhone, ".");
end;

