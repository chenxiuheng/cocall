require('libs.commons');
require('libs.db');
require('conference.conferenceService');

freeswitch.API():execute('bgapi', "lua conference/task.lua");

local ids = getUpdatedConferenceIds(7000 + 100);
for k, v in pairs(ids) do
    print("kva", k, v);
end;


local toUsers = {};
table.insert(toUsers, '10261');
table.insert(toUsers, '10752');
table.insert(toUsers, '10605');
batchSendSMS('110', toUsers, 'lin1', 'lin2', 'lin3');

batchSendSMS('110', {}, 'lin1', 'lin2', 'lin3');



local key2 = 'key2';
local value  = 'values';
local var a = {key=value, key2=key2};
print("value", a.key);
print("key2", a.key2);

local x
x = string.gsub("hello world", "(%w+)", "%1 %1");
print(x);

 x = string.gsub("hello world", "%w+", "%0 %0", 1);
print(x);

local sqlstring = {}
function sqlstring.format (format, ...)
    local args = {...};
    
    local index = 1;     
    local sql = '';
    local param;
    for match in string.gmatch(format..'%s', "(.-)%%s") do
        if nil ~= args[index] then
            -- replace "'" to "''" for postgres
            sql = sql .. match .. string.gsub(args[index], "'", "''");
        else 
            sql = sql .. match;
        end;

        index = index + 1;
    end

    return sql;
end;

local sql = sqlstring.format("select * from t_user where c_id='%s'", '"'.."'");

print( sql );
sql = "select * from t_user where c_id='%s'";
executeQuery(sql);

print("sql=", sql.format("select from a'%s', a '%s'", "b'--", 'c'));



