
function api_dispatch_member_energy (confPhone)
    local service;
    service = newConferenceService(confPhone);
    service.dispatchMemberEnergies();
end;

--  execute if has argv
local confPhone = argv[1];
if nil ~= confPhone then
    api_dispatch_member_energy (confPhone);
end;
