local api = freeswitch.API();

require('libs.db');
require('libs.commons');
require('conference.conferenceService');

local timeout = 1300;
local service;
local conferenceIds = getUpdatedConferenceIds(timeout);
for i, confPhone in ipairs(conferenceIds) do
    clearConferenceUpdated(confPhone);

    service = newConferenceService(confPhone);
    service.dispatchMemberStates();
    freeswitch.consoleLog('info', 'dispatch conference['..confPhone..'] states to its members \n');
end;



