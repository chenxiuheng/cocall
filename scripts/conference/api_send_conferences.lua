-- ================================================================
-- call as: "conference/api_send_conferences.lua 110, 1018"
-- use 110 as sender, and then send conference_list to user/1018
-- ================================================================

require('libs.db');
require('libs.commons');
require('conference.conferenceService');

local sender = argv[1];
local to_user = argv[2];

if nil ~= sender and nil ~= to_user then
    local msg = nil;
    local conferences = getMyConferences(to_user);

    for i, conference in ipairs(conferences) do
        if nil ~= msg then
            msg = msg ..'\n'..formatConferenceFull(conference);
        else 
            msg = formatConferenceFull(conference);
        end;
    end;

    if nil ~= msg then
        sendSMS(sender, to_user, 'conference-list', msg);
    end;
else
    getLogger('task_send_conferences').error(string.format('illegal arguments (%s, %s)', argv[1], argv[2]));
end;
