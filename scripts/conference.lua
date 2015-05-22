local api = freeswitch.API();
local scripts_base_dir = api:execute("global_getvar", "base_dir")..'/scripts';
if nil == string.find(package.path, scripts_base_dir) then
    package.path = package.path..';'..
                scripts_base_dir..'/?.lua'..';';
end;

require('libs.db');


local attempt = 1
local max_attempts = 3

local callerNum = 0;
local conf_num = 0;

function session_hangup_hook()
  freeswitch.consoleLog("NOTICE", "Session hangup: \n")
end

session:answer();
session:setHangupHook("session_hangup_hook")


if session:ready() then
    callerNum =  session:getVariable("caller_id_number");
    conf_num  = session:getVariable("destination_number");
    freeswitch.consoleLog("NOTICE","conferenceNo:"..conf_num..", callerNum = ".. callerNum .."--\n");
end


local foundIt = false;
local sql = string.format("SELECT  c_phone_no, n_can_hear, n_can_speak, n_engery_level, c_name, n_is_modirator FROM t_conference_member  where c_conference_phone_no ='%s' ", conf_num);
local numRows = executeQuery(sql, function(row)
        if not foundIt and row['c_phone_no'] == callerNum then

            if '1' == row['n_is_modirator'] or 1 == row['n_is_modirator'] then
                session:execute("conference", string.format("%s@default +flags{endconf|moderator}", conf_num))
            else

                session:execute("conference", string.format("%s@default ", conf_num))
            end;

            foundIt = true;
        end;
end);


if numRows < 1 then
    print("NO LIMIT LOGIN for zero members in conference[".. conf_num .."]");
    session:execute("conference", string.format("%s@default  video-floor-only", conf_num))
elseif not foundIt then
    freeswitch.consoleLog("warning","can't find member["..callerNum.."] in conference[".. conf_num .."]--\n");

    session:hangup();
end;
