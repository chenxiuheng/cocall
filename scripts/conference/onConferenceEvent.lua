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
local action = event:getHeader('Action');
local old_id = event:getHeader('Old-ID');
local new_id = event:getHeader('New-ID');
local energy = event:getHeader('Current-Energy');
local level = event:getHeader('Energy-Level');

local ext = {};
ext['user_id'] = user;
ext['old_id'] = old_id;
ext['new_id'] = new_id;
ext['current_energy'] = energy;
ext['energy_level'] = level;
saveConferenceEvent(confPhone, action, memberId, ext);


local hasVideo = false;
if 'true' == event:getHeader('Video') then hasVideo = true; end;
    

local service = newConferenceService(confPhone);
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
    if nil ~= last_member_id and '' ~= last_member_id and last_member_id ~= memberId then
        api:execute('conference', confPhone..' kick '..last_member_id);
        logger.warn("conference ", confPhone, " kick last member =", last_member_id, "new member = ", memberId);
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
    logger.info("conference ", confPhone, " video-floor-change  ", old_id, ' --> ', new_id);

    if new_id ~= 'none' and nil ~= new_id then
        local members = service.getMembers('moderator');
        for i, member in ipairs(members) do
            local is_in = member['is_in'];

            if not isTrue(is_in ) or '' == member['member_id']  then
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
    if ('0' == level or 0 == leven) then
       level = '300'; -- default is 300 in freeswitch
    end;
    updateConferenceMemberEnergy(confPhone, user, energy, level);

    service.notifyAll();
elseif action == 'stop-talking' then
    energy = '0';
    if ('0' == level or 0 == leven) then
       level = '300'; -- default is 300 in freeswitch
    end;
    updateConferenceMemberEnergy(confPhone, user, energy, level);

    service.notifyAll();
end;







