-- odbc 
local globalDSN = freeswitch.getGlobalVariable('odbc-dsn');
local dsn =  globalDSN or "odbc://freeswitch::";
if nil == globalDSN then
     freeswitch.consoleLog("warning", "use default ODBC-DSN:[" .. dsn .."\n");   
end;


local dbh = freeswitch.Dbh(dsn);

-- use sql query
function executeQuery(sql, callback) 

    local numRows = 0;
    if dbh:connected() then
        freeswitch.consoleLog("notice", sql .. "\n") 

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
    if dbh:connected() then
        freeswitch.consoleLog("info", sql .. "\n") ;
print(sql);
        dbh:query(sql);
    else 
        freeswitch.consoleLog("warning", "cannot connect to database by " .. dsn .. "\n")                        
    end
        
end
