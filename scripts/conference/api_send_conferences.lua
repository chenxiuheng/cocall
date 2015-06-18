-- ================================================================
-- call as: "conference/api_send_conferences.lua 110, 1018"
-- use 110 as sender, and then send conference_list to user/1018
-- ================================================================

require('libs.db');
require('libs.commons');
require('conference.conferenceService');

local sender = argv[1];
local to_user = argv[2];

local logger = getLogger('task_send_conferences');
if nil ~= sender and nil ~= to_user then
    local msg = 'conference-list';
    local conferences = getMyConferences(to_user);

    for i, conference in ipairs(conferences) do
         msg = msg ..'\n'..formatConferenceFull(conference);
    end;


    sendSMS(sender, to_user, msg);

else
    logger.error(string.format('illegal arguments (%s, %s)', argv[1], argv[2]));
end;
