--- ====================================
--- call on member join conference  ----
--- ====================================

local api = freeswitch.API();
require('libs.commons');
require('libs.db');
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
    local logger = getLogger('com.thunisoft.cocall.conference.events');
    logger.info(confPhone, action, "member:", user, '/', memberId);


    -- user state offen be no in, why ?
    if action == 'start-talking' then
        setConferenceMemberIn(confPhone, user, memberId);
    end;


    -- events
    if action == 'conference-create' then
        service.setIsRunning(true);
    elseif action =='conference-destroy' then
        service.setIsRunning(false);
    elseif action =='add-member' then 
        setConferenceMemberIn(confPhone, user, memberId);

        -- kick the member use same user no
        local members = getConferenceMembers(confPhone, user);
        for i, member in pairs(members) do
            if memberId ~= member['member_id'] and nil ~= member['member_id'] then
                api:execute('conference', confPhone..' kick '.. member['member_id']);
                logger.info("conference ", confPhone, " kick ", member['member_id']);
            end;
        end;

        -- change moderator's screen if I am the moderator
        local members = getConferenceMembers(confPhone, "moderator");
        for i, member in pairs(members) do

            if member['user'] == user then
                api:execute('conference', confPhone..' vid-floor '..memberId.." force");
                logger.info("conference ", confPhone, " set vid-floor ", user, ' because of he is moderator');
            end;
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
    elseif action == 'start-talking' or action == 'stop-talking' then
        local energy = event:getHeader('Current-Energy');
        local level = event:getHeader('Energy-Level');
        if ('0' == level or 0 == leven) then
           level = '300'; -- default is 300 in freeswitch
        end;


        local msg = string.format("%s;%s/%s", user, energy, level);
        service.sayTo('all', user, 'conference-energy', msg);
    end;
else
    local action = event:getHeader('Action');
    if action == 'add-member' then 
        freeswitch.msleep(1000);

        freeswitch.API():execute('conference', conf_name..' transfer '.. confPhone ..' '..memberId);
    end;
end;






