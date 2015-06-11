local api = freeswitch.API();
require('libs.commons');
require('libs.db');
require('conference.conferenceService');


local caller_id = 0;
local conf_num = 0;
caller_id =  session:getVariable("caller_id_number");
conf_num  = session:getVariable("destination_number");

function session_hangup_hook()
  freeswitch.consoleLog("NOTICE", "Session hangup: \n")
end

session:answer();
session:setHangupHook("session_hangup_hook")



local foundIt = false;
if session:ready() then
    local service = newConferenceService(conf_num);
    local members = service.getMembers(caller_id);
    for i, member in ipairs(members)  do

        --  because of 
        freeswitch.consoleLog("WLRNING", "WAITING: \n")
        freeswitch.msleep(3 * 1000);
        freeswitch.consoleLog("WARNING", "stop WAITING: \n")

        foundIt = true;
        local conf_name = string.format("%s@ultrawideband", conf_num, caller_id);
        session:execute("conference", conf_name)
        freeswitch.consoleLog("NOTICE", "create template conference " .. conf_name);
    end;


    if not foundIt then
        sendSMS(conf_num, caller_id, 'WARNING', string.format("caller[%s] not belong conference[%s]", caller_id, conf_num));
        session:hangup();
    end;
end;


