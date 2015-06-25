require('libs.commons');
require('libs.db');
require('task.taskService');
require('user.userService');
require('conference.conferenceService');

local num_conferences = argv[1];

local name = 'conference_'..num_conferences;
local creator = '1018';
local creatorName = 'name_' .. creator;
local conf_phone = createConference (name, creator, creatorName);
local service = newConferenceService(conf_phone);

local num_users = 10;
local member = {};
while num_users > 0 do
    num_users = num_users - 1;
    member['user'] = "10"..(num_conferences % 10000 + num_users * 10001);
    member['name'] = string.format('user/%s/%s', member['user'], num_conferences);
    
    service.addMember(member, true);
end;
