local api = freeswitch.API();
require('libs.commons');
require('libs.db');
require('conference.conferenceService');


local caller_id = 0;
local conf_num = 0;
caller_id =  session:getVariable("caller_id_number");
conf_num  = session:getVariable("destination_number");

session:answer();

local foundIt = false;
local conf = getConferenceInfo(conf_num);
if nil ~= conf and '1' == conf['valid'] then
    local service = newConferenceService(conf_num);
    local members = service.getMembers(caller_id);
    service.readMemberList(caller_id);

    for i, member in ipairs(members)  do
        --  wait user audio+video send to FS
        --     if don't wait, FS will has problem(s) when punch NAT
        freeswitch.consoleLog("info", string.format("user %s waiting to join conference %s\n", caller_id, conf_num));
        freeswitch.msleep(3 * 1000); -- because default RTP timeout is 1800 


        -- if session is NOT disavailable
        if session:ready() then
            foundIt = true;
            local conf_name = string.format("%s@ultrawideband", conf_num, caller_id);
            session:execute("conference", conf_name)

            freeswitch.consoleLog("notice", string.format("user %s joined conference %s\n", caller_id, conf_num));
        else
            freeswitch.consoleLog("warning", string.format("session NOT ready, user %s canceled join conference %s \n", caller_id, conf_num));
        end;
    end;
end;


if not foundIt then
    
    sendSMS(conf_num, caller_id, 'conference-forbidden', string.format("caller[%s] not belong conference[%s]", caller_id, conf_num));
    session:hangup();
end;


