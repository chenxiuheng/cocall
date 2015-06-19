-- ================================================================
-- call as: "conference/api_dispatch_member_energy.lua 3401"
-- dispatch conference energy info to its members
-- ================================================================

require('libs.db');
require('libs.commons');
require('conference.conferenceService');

local confPhone = argv[1];
local service;
service = newConferenceService(confPhone);
service.dispatchMemberEnergies();
