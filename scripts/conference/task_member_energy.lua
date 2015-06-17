local api = freeswitch.API();

require('libs.db');
require('libs.commons');
require('conference.conferenceService');


freeswitch.consoleLog('warn', 'dispatch conference member energies\n');

local service;
local conferenceIds = getRunningConferenceIds(timeout);
for i, confPhone in ipairs(conferenceIds) do
    service = newConferenceService(confPhone);
    service.dispatchMemberEnergies();
    freeswitch.consoleLog('debug', 'dispatch conference['..confPhone..'] member energies\n');
end;
