
-- odbc
local globalDSN = freeswitch.getGlobalVariable('odbc-dsn');
local dsn =  globalDSN or "odbc://freeswitch::";
if nil == globalDSN then
     freeswitch.consoleLog("warning", "use default ODBC-DSN:[" .. dsn .."\n");
end;


dbh = nil;
sqlstring = {}
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

-- use sql query
function executeQuery(sql, callback)
    if nil == dbh then dbh = freeswitch.Dbh(dsn); end;

    local numRows = 0;
    if dbh:connected() then
        --freeswitch.consoleLog("debug", sql .. "\n")

        dbh:query(sql, function(row)
            numRows = numRows + 1;

            if (nil ~= callback)  then
                callback(row);
            end
        end);
    else
        freeswitch.consoleLog("warning", "cannot connect to database by " .. dsn .. "\n")
    end

    return numRows;
end;

function executeUpdate(sql)
    if nil == dbh then dbh = freeswitch.Dbh(dsn); end;

    if dbh:connected() then
        freeswitch.consoleLog("notice", sql .. "\n") ;
        dbh:query(sql);
    else
        freeswitch.consoleLog("warning", "cannot connect to database by " .. dsn .. "\n")
    end

end

