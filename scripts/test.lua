require('libs.commons');
require('libs.db');
require('conference.conferenceService');

print(executeUpdate("update t_id set c_id='conf2' where c_id='conf'"));
print(executeUpdate("update t_id set c_id='conf' where c_id='conf2'"));

local a = {};
a.sayHello = function(txt)
    print('sayHello:', txt);
end;

a['sayHello']('miss')

--字符串分割函数
--传入字符串和分隔符，返回分割后的table
function string.split(str, delimiter)
	if str==nil or str=='' or delimiter==nil then
		return nil
	end
	
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local cmd = 'conference/api_send_conferences.lua   110 10605';
local segs = string.split(cmd, '(%s+)');
for i, seg in ipairs(segs) do
    print("p"..i, seg);
end;


while true do
    if 1 < 2 then break;end;
end;
print(now());
local ntime = os.clock();
print('curTime:', ntime);
local sql = sqlstring.format("select %s from t", 'seg1', 'seg2');
print(sql);


local toUsers = {};
table.insert(toUsers, '10261');
table.insert(toUsers, '10752');
table.insert(toUsers, '10605');
batchSendSMS('110', toUsers, 'lin1', 'lin2', 'lin3');

batchSendSMS('110', {}, 'lin1', 'lin2', 'lin3');


