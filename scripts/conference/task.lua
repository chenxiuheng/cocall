local api = freeswitch.API();

require('libs.db');
require('libs.commons');
require('conference.conferenceService');

local timeout = 1300;
local service;
local conferenceIds = getUpdatedConferenceIds(timeout);
for i, confPhone in ipairs(conferenceIds) do
    service = newConferenceService(confPhone);
    service.dispatchMemberStates();
    clearConferenceUpdated(confPhone);
    freeswitch.consoleLog('info', 'dispatch conference['..confPhone..'] states to its members \n');
end;



