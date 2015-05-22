require('libs.db');
require('libs.commons');
require('user.userService');
require('conference.conferenceService');


-- tell others , I am online
local user = event:getHeader('from-user');
local confs = getMyConferences(user, true);
for i, conf in ipairs(confs) do
    local servcie = newConferenceService(conf['conference']);
    servcie.notifyAll();
end;
