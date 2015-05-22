--- ====================================
--- call on member join conference  ----
--- ====================================

local api = freeswitch.API();
local scripts_base_dir = api:execute("global_getvar", "base_dir")..'/scripts';
if nil == string.find(package.path, scripts_base_dir) then
    package.path = package.path..';'..
                scripts_base_dir..'/?.lua'..';';
end;
require('libs.db');
require('libs.commons');
require('conference.conferenceService');


local confPhone = event:getHeader('Conference-Name');
local memberId = event:getHeader('Member-ID');
local memberType = event:getHeader('Member-Type');
local user = event:getHeader('Caller-Caller-ID-Number');

-- print(event:serialize());

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
        local is_in = member['is_in'];

        if member['user'] == user and isTrue(is_in) then
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
            logger.info("conference ", confPhone, " moderator leave out, and set speak free ");
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




