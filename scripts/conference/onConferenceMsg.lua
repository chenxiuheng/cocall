local api = freeswitch.API();

require('libs.db');
require('libs.commons');
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
        for user, name in string.gmatch(params..'\n', "([^;]*);([^\n]*)\n") do
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
    elseif action == 'conference_kick' then
        for user in string.gmatch(params..'\n', "([^\n]*)\n") do
            if '' ~= user then
                service.kick(user, from_user);
                sendSMS(confPhone, user, "conference-kick", service.toSimpleString());

            end;
        end;

        service.notifyAll();
    elseif action == 'conference_destroy' then
        local members = service.getMembers('all');
        for i, member in ipairs(members) do
            sendSMS(confPhone, member['user'], 'conference-destroy', service.toSimpleString());
        end;

        service.destroy();
    elseif action == 'conference_mute'  then
        for user in string.gmatch(params, "([^\n]*)\n") do
            service.mute(user);
            logger.notice(from_user, 'mute', user);
        end;

        service.notifyAll();
    elseif action == 'conference_unmute' then
        for user in string.gmatch(params, "([^\n]*)\n") do
            service.unmute(user);
            logger.notice(from_user, 'unmute', user);
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
                service.sayTo(dstUsers, from_user, txt);
            end;
        end;

        if not sentIt then
            service.sayTo('all', from_user, txt);
        end;

    end;

else
    logger.warn("illegal arguments from ", from_user, "to", confPhone, ".");
end;

