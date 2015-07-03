require('conference.conferenceService');

function api_dispatch_member_list (confPhone, dstUsr)
    local service;
    service = newConferenceService(confPhone);
    service.dispatchMemberStates(dstUsr);
end;


--  execute if has argv
local confPhone = argv[1];
local dstUsr = argv[2];
if nil ~= confPhone then
    api_dispatch_member_list (confPhone, dstUsr);
end;
