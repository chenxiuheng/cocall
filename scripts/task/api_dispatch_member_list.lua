require('conference.conferenceService');

function api_dispatch_member_list (confPhone)
    local service;
    service = newConferenceService(confPhone);
    service.dispatchMemberStates();
end;


--  execute if has argv
local confPhone = argv[1];
if nil ~= confPhone then
    api_dispatch_member_list (confPhone);
end;
