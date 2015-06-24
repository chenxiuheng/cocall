require('libs.commons');
require('libs.db');
require('task.taskService');
require('conference.conferenceService');
require('user.userService');

-- ///////////////////////////////////////////////
--   API define(s)
-- ///////////////////////////////////////////////
local A = {};
A.api_send_conferences = function (from_user, to_user)
    local msg = 'conference-list';
    local conferences = getMyConferences(to_user);

    for i, conference in ipairs(conferences) do
         msg = msg ..'\n'..formatConferenceFull(conference);
    end;

    sendSMS(from_user, to_user, msg);
end;

A.api_dispatch_member_list = function (confPhone)
    local service;
    service = newConferenceService(confPhone);
    service.dispatchMemberStates();
end;

A.api_dispatch_member_energy = function (confPhone)
    local service;
    service = newConferenceService(confPhone);
    service.dispatchMemberEnergies();
end;

A.api_clear_registrationExt = function()
   -- don't clear
   -- deleteRegistrationExtOutOfDate();
end;
-- // end

local logger = getLogger('task_async_executor');
local tasks = getExecuteTasks();

local func;
for index, task in pairs(tasks) do
    local id        = task['id'];
    local cmd       = task['cmd'];
    local timeout   = task['timeout'];
    local task_type = task['type'];
    local args      = task['args'];

    -- clear task
    if task_type =='timeout' then
        clearTimeout(id);
    else
        recycleInterval(id, timeout); 
    end;

    -- invoke
    func = A[cmd];
    if (nil ~= func) then
        func(args[1], args[2], args[3], args[4]);
    else
        logger.error('unknown cmd ', cmd);
    end;
end;
