require('libs.db');
require('libs.commons');
require('user.userService');
require('conference.conferenceService');

local from_user = event:getHeader("from-user");
local call_id = event:getHeader("call-id");


-- tell DB, I am out
if nil ~= from_user and nil ~= call_id then
    userLogout(from_user, call_id);
end;

