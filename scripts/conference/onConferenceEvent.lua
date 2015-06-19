--- ====================================
--- call on member join conference  ----
--- ====================================

local api = freeswitch.API();
require('libs.commons');
require('libs.db');
require('task.taskService');
require('conference.conferenceService');


local conf_name = event:getHeader('Conference-Name');
local confPhone = conf_name;
local memberId = event:getHeader('Member-ID');
local memberType = event:getHeader('Member-Type');
local user = event:getHeader('Caller-Caller-ID-Number');



local isTemplateConference = false;
for v1, v2, v3 in  string.gmatch(conf_name, "(template)_([^_]+)_([^_]+)") do
    isTemplateConference = true;
    confPhone = v2;
end


-- print(event:serialize());

if not isTemplateConference then
    local hasVideo = false;
    if 'true' == event:getHeader('Video') then hasVideo = true; end;
        

    local service = newConferenceService(confPhone);
    local action = event:getHeader('Action');
    local logger = getLogger('conference.events');
    logger.info(confPhone, action, "member:", user, '/', memberId);

    -- events
    if action == 'conference-create' then
        service.setIsRunning(true);
    elseif action =='conference-destroy' then
        service.setIsRunning(false);
    elseif action =='add-member' then 
        -- save as DB
        local last_member_id;
        local is_moderator;
        last_member_id, is_moderator = setConferenceMemberIn(confPhone, user, memberId);

        -- kick the member use same user no
        if nil ~= last_member_id then
            api:execute('conference', confPhone..' kick '..last_member_id);
            logger.warn("conference ", confPhone, " kick ", last_member_id);
        end;

        -- change moderator's screen if I am the moderator
        if is_moderator then
            api:execute('conference', confPhone..' vid-floor '..memberId.." force");
            logger.info("conference ", confPhone, " set vid-floor ", user, ' because of he is moderator');
        end;

        service.notifyAll();
    elseif action == 'del-member' and nil ~= user then
        setConferenceMemberOut(confPhone, user, memberId);

        -- clear-vid-floor if I am moderator
        local isModerator = false;
        local members = getConferenceMembers(confPhone, 'moderator');
        for i, member in pairs(members) do
            if member['user'] == user then
                isModerator = true;

                -- moderator leave out
                api:execute('conference', confPhone..' clear-vid-floor');
                logger.info("conference ", confPhone, " moderator ", user, "leave out, and set speak free ");
            end;
        end;

        -- if moderator leave out, set a non-moderator as speaker, but not force
        if isModerator then
            local setSpeaker = false;
            local members = getConferenceMembers(confPhone, 'non_moderator', user);
            for i, member in pairs(members) do
                if not setSpeaker and isTrue(member['is_in']) then
                    setSpeaker = true;
                    api:execute('conference', confPhone..' vid-floor '..member['member_id']);
                    logger.info("conference ", confPhone, " moderator leave out, and set ", member['user'], "as speaker, but not force");
                end;
            end;
        end;

        service.notifyAll();
    elseif action == 'video-floor-change' then
        local old_id = event:getHeader('Old-ID');
        local new_id = event:getHeader('New-ID');
        logger.info("conference ", confPhone, " video-floor-change  ", old_id, ' --> ', new_id);

        if new_id ~= 'none' and nil ~= new_id then
            local members = service.getMembers('moderator');
            for i, member in ipairs(members) do
                local is_in = member['is_in'];
                logger.info("conference ", confPhone, " user  = ", user, ', moderator = ', member['user']);
                logger.info("conference ", confPhone, " moderator is_in = ", isTrue(is_in), ', member_id = ', member['member_id']);

                if not isTrue(is_in ) then
                    logger.warn("conference ", confPhone, " moderator is NOT online, change to member_id = ", new_id);
                elseif member['member_id'] ~= new_id then
                    local cmd_video_floor_change = confPhone..' vid-floor '.. member['member_id']..' force';
                    api:execute('conference', cmd_video_floor_change);
                    service.notifyAll();

                    logger.warn("execute conference ", cmd_video_floor_change);
                end;
            end;
        end;

    elseif action == 'start-talking' then
        local energy = event:getHeader('Current-Energy');
        local level = event:getHeader('Energy-Level');
        if ('0' == level or 0 == leven) then
           level = '300'; -- default is 300 in freeswitch
        end;
        updateConferenceMemberEnergy(confPhone, user, energy, level);

        -- // dispatch member energy after 500ms
        local task_id = string.format("conference/%s/energy", confPhone);
        local cmd = "conference/api_dispatch_member_energy.lua "..confPhone;
        setTimeoutIfAbsent(task_id, cmd, 500);
    elseif action == 'stop-talking' then
        local energy = '0';
        local level = event:getHeader('Energy-Level');
        if ('0' == level or 0 == leven) then
           level = '300'; -- default is 300 in freeswitch
        end;
        updateConferenceMemberEnergy(confPhone, user, energy, level);

        -- // dispatch member energy after 500ms
        local task_id = string.format("conference/%s/energy", confPhone);
        local cmd = "conference/api_dispatch_member_energy.lua "..confPhone;
        setTimeoutIfAbsent(task_id, cmd, 500);
    end;
else
    local action = event:getHeader('Action');
    if action == 'add-member' then 
        freeswitch.msleep(1000);

        freeswitch.API():execute('conference', conf_name..' transfer '.. confPhone ..' '..memberId);
    end;
end;






