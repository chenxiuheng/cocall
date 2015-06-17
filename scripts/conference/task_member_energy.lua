local api = freeswitch.API();

require('libs.db');
require('libs.commons');
require('conference.conferenceService');


local service;
local conferenceIds = getRunningConferenceIds();
for i, confPhone in ipairs(conferenceIds) do
    service = newConferenceService(confPhone);
    service.dispatchMemberEnergies();
    freeswitch.consoleLog('debug', 'dispatch conference['..confPhone..'] member energies\n');
end;
