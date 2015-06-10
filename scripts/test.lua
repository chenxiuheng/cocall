require('libs.commons');
require('libs.db');
require('conference.conferenceService');

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



