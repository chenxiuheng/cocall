
function setTimeout(id, cmd, millisec)
    local sql;
    if nil == id then id = 'auto_'..cmd; end;

    -- select the row if existed
    local existed = false;
    local executed = false;
    sql = sqlstring.format(
            "select n_executed as executed from t_task_timeout where id = '%s'",
            id
        );
    executeQuery(sql, function(row)
        existed = true;
    end);

    -- save or update force
    if not existed then
        sql = sqlstring.format(
                "insert into t_task_timeout (id, d_created, n_executed, d_execute, c_lua_cmd)"..
                "values ('%s', now(), 2, now() + interval '%s millisecond', '%s')",
                id, millisec, cmd
            );
        executeUpdate(sql);
    else
        sql = sqlstring.format(
                "update t_task_timeout set d_created = now(), "..
                "  n_executed = 2, "..
                "  d_execute = now() + interval '%s millisecond',"..
                "  c_lua_cmd='%s'"..
                " where id = '%s' ",
                millisec, cmd, id
            );
        executeUpdate(sql);
    end;

    return id;
end;

function setTimeoutIfAbsent(id, cmd, millisec)
    local sql;
    if nil == id then id = 'auto_'..cmd; end;

    -- select the row if existed
    local existed = false;
    local executed = false;
    sql = sqlstring.format(
            "select n_executed as executed from t_task_timeout where id = '%s'",
            id
        );
    executeQuery(sql, function(row)
        existed = true;
        executed = ('1' == row['executed']);
    end);

    -- save or update if need
    if not existed then
        sql = sqlstring.format(
                "insert into t_task_timeout (id, d_created, n_executed, d_execute, c_lua_cmd)"..
                "values ('%s', now(), 2, now() + interval '%s millisecond', '%s')",
                id, millisec, cmd
            );
        executeUpdate(sql);
    elseif executed then
        sql = sqlstring.format(
                "update t_task_timeout set d_created = now(), "..
                "  n_executed = 2, "..
                "  d_execute = now() + interval '%s millisecond',"..
                "  c_lua_cmd='%s'"..
                " where id = '%s' ",
                millisec, cmd, id
            );
        executeUpdate(sql);
    else
        -- // existed and has't been executed, do nothing
    end;

    return id;
end;

function clearTimeout(id)
    local sql;
    sql = sqlstring.format(
            "update t_task_timeout set n_executed = 1 where id='%s'",
            id
        );
    executeUpdate(sql);
end;

function getExecuteTasks()
    local sql;
    sql = sqlstring.format(
            " select id, c_lua_cmd as cmd, -1 as timeout, 'timeout' as type "..
            " from t_task_timeout where n_executed = 2 and d_execute <= now() "..
            "union all"..
            " select id, c_lua_cmd as cmd, n_timeout as timeout, 'interval' as type "..
            " from t_task_interval where d_execute <= now() "
        );

    local key;
    local cmd;
    local tasks = {};
    executeQuery(sql, function(row)
        row['timeout'] = tonumber(row['timeout']);
        table.insert(tasks, row);
    end);

    return tasks;
end;

function clearInterval(id)
    local sql;
    sql = sqlstring.format(
            "delete from t_task_interval where id='%s'",
            id
        );
    executeUpdate(sql);
end;

function setInterval(id, cmd, millisec)
    clearInterval(id);

    local sql;
    sql = sqlstring.format(
            "insert into t_task_interval (id, d_created, d_execute, n_timeout, c_lua_cmd)"..
            " values('%s', now(), now() + interval '%s millisecond', %s, '%s')",
            id, millisec, millisec, cmd
        );
    executeUpdate(sql);
end;

function recycleInterval(id, millisec)
    local sql;
    sql = sqlstring.format(
            "update t_task_interval set d_execute = now() + interval '%s millisecond' where id='%s'",
            millisec, id
        );
    executeUpdate(sql);  
end;
