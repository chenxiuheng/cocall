local api = freeswitch.API();

require('libs.db');
require('libs.commons');
require('user.userService');


deleteRegistrationExtOutOfDate();


freeswitch.consoleLog('debug', 'delete registration ext out Of date \n');
