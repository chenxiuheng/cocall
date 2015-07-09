
-- ================================================
--   用户：同时在线人数记录为 3W
--   视频会议：每天 300 个， 5 年 300 * 365 * 5 个
--           同时每个会议中 10 个人，
--   定时任务: 3W 人，30分钟内登陆。视频会议列表请求数为 ？？？
-- ================================================
require('libs.commons');
require('libs.db');
require('task.taskService');
require('user.userService');
require('conference.conferenceService');


-- insert conference(s)
local num_conferences = 300 * 365 * 5;
while num_conferences > 0 do
    num_conferences = num_conferences - 1;
    
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
end;



