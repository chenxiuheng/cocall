require('libs.commons');
require('libs.db');
require('conference.conferenceService');

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


