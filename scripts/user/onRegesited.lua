require('libs.db');
require('libs.commons');
require('user.userService');
require('conference.conferenceService');


-- save registeration info
local call_id = event:getHeader('call-id');
local profile = event:getHeader('profile-name');
local user_id = event:getHeader('username');
local user_agent = event:getHeader('user-agent');
local realm = event:getHeader('realm');
local local_host = event:getHeader('to-host');
local contact = event:getHeader('contact');
local expires = event:getHeader('expires');
if nil == expires then expires = 3600; end;

if nil ~= call_id and nil ~= profile and nil ~= user_id then
    saveRegistrationExt(call_id, profile, user_id, user_agent, realm, local_host, contact, expires);
end;


-- tell others , I am online
local user = event:getHeader('from-user');
local confs = getMyConferences(user, true);
for i, conf in ipairs(confs) do
    local servcie = newConferenceService(conf['conference']);
    servcie.notifyAll();
end;


