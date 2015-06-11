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
end;

freeswitch.consoleLog('debug', 'dispatch conference states to its members \n');


