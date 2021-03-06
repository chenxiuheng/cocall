
-- odbc
local globalDSN = freeswitch.getGlobalVariable('odbc-dsn');
local dsn =  globalDSN or "odbc://freeswitch::";
if nil == globalDSN then
     freeswitch.consoleLog("warning", "use default ODBC-DSN:[" .. dsn .."\n");
end;

local autoRelease = true;


local dbh = nil;
sqlstring = {}
function sqlstring.format (format, ...)
    local args = {...};

    local index = 1;
    local arg = nil;
    local buf = newSqlBuilder();
    for match in string.gmatch(format..'%s', "(.-)%%s") do
        if nil ~= args[index] then
            arg = args[index];
            arg = string.gsub(arg, "'", "''"); -- replace "'" to "''" for postgres
            arg = string.gsub(arg, ";", " ");  -- special char used for send sms api 
            arg = string.gsub(arg, "\r", " "); -- 
            arg = string.gsub(arg, "\n", "  ");
        
            buf.append(match).append(arg);
        else
            buf.append(match);
        end;

        index = index + 1;
    end

    return buf.toString();
end;

function sqlformat(format, arg)
    if nil == arg then arg = '' ;
    else
        arg = string.gsub(arg, "'", "''"); -- replace "'" to "''" for postgres
        arg = string.gsub(arg, ";", " ");  -- special char used for send sms api 
        arg = string.gsub(arg, "\r", " "); -- 
        arg = string.gsub(arg, "\n", "  ");
    end;

    return string.format(format, arg);
end;

function newSqlBuilder(initString)
    local chars = {};
    local self = {};

    self.append = function (arg, param)

        if nil == param then
            if nil == arg then arg = '' end;
            table.insert(chars, arg);
        else
            self.format(arg, param);
        end;

        return self;
    end;

    self.format = function (format, param)
        table.insert(chars, sqlformat(format, param));

        return self;
    end;

    self.toString = function()
        return table.concat(chars);
    end;

    self.query = function(callback)
        return executeQuery(self.toString(), callback);
    end;

    self.list = function()
        local rows = {};

        executeQuery(self.toString(), function(row)
            table.insert(rows, row);
        end);

        return rows;
    end;

    self.update = function()
        return executeUpdate(self.toString());
    end;

    if nil ~= initString then
        self.append(initString);
    end;

    return self;
end;

function setDbhAutoRelease(auto)
    autoRelease = auto;
end;

function releaseDbh()
    if nil ~= dbh then
        dbh:release();
        dbh = nil;
    end;
end; 

function executeQuery(sql, callback)
    if nil == dbh then dbh = freeswitch.Dbh(dsn); end;

    local numRows = 0;
    if dbh:connected() then
        freeswitch.consoleLog("debug", sql .. "\n")

        dbh:query(sql, function(row)
            numRows = numRows + 1;

            if (nil ~= callback)  then
                callback(row);
            end
        end);

        if autoRelease then
            releaseDbh();
        end;
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
        local affected = dbh:affected_rows();


        if autoRelease then
            releaseDbh();
        end;

        return affected;
    else
        freeswitch.consoleLog("warning", "cannot connect to database by " .. dsn .. "\n")
        return 0;
    end

end

function now()
    if nil == dbh then dbh = freeswitch.Dbh(dsn); end;

    local now = nil;
    if dbh:connected() then
        local sql = "select extract(epoch from now()) * 1000 as t";
        freeswitch.consoleLog("debug", "select now()\n") ;

        dbh:query(sql, function(row)
            now = tonumber(row['t']);
        end);


        if autoRelease then
            releaseDbh();
        end;

    end

    return now;
end;


