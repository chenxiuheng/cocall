local api = freeswitch.API();

require('libs.db');
require('libs.commons');
require('conference.conferenceService');


deleteRegistrationExtOutOfDate();


freeswitch.consoleLog('debug', 'delete registration ext out Of date \n');
