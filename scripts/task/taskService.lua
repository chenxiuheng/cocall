
function setTimeout(id, cmd, millisec)
    local sql;
    if nil == id then id = 'auto_'..cmd; end;

    -- split cmd, read api name and params
    local segs = string.split(cmd, '(%s+)');
    local api = segs[1];
    local args_1 = segs[2];
    local args_2 = segs[3];
    local args_3 = segs[4];
    local args_4 = segs[5];


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
                "insert into t_task_timeout (id, d_created, n_executed, d_execute, c_api, c_args_1, c_args_2, c_args_3, c_args_4)"..
                "values ('%s', now(), 2, now() + interval '%s millisecond', '%s', '%s', '%s', '%s', '%s')",
                id, millisec, api, args_1, args_2, args_3, args_4
            );
        executeUpdate(sql);
    else
        sql = sqlstring.format(
                "update t_task_timeout set d_created = now(), "..
                "  n_executed = 2, "..
                "  d_execute = now() + interval '%s millisecond',"..
                "  c_api='%s',"..
                "  c_args_1='%s',"..
                "  c_args_2='%s',"..
                "  c_args_3='%s',"..
                "  c_args_4='%s',"..
                " where id = '%s' ",
                millisec, api, args_1, args_2, args_3, args_4, id
            );
        executeUpdate(sql);
    end;

    return id;
end;

function setTimeoutIfAbsent(id, cmd, millisec)
    local sql;
    if nil == id then id = 'auto_'..cmd; end;

    -- split cmd, read api name and params
    local segs = string.split(cmd, '(%s+)');
    local api = segs[1];
    local args_1 = segs[2];
    local args_2 = segs[3];
    local args_3 = segs[4];
    local args_4 = segs[5];

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
                "insert into t_task_timeout (id, d_created, n_executed, d_execute, c_api, c_args_1, c_args_2, c_args_3, c_args_4)"..
                "values ('%s', now(), 2, now() + interval '%s millisecond', '%s', '%s', '%s', '%s', '%s')",
                id, millisec, api, args_1, args_2, args_3, args_4
            );
        executeUpdate(sql);
    elseif executed then
        sql = sqlstring.format(
                "update t_task_timeout set d_created = now(), "..
                "  n_executed = 2, "..
                "  d_execute = now() + interval '%s millisecond',"..
                "  c_api='%s',"..
                "  c_args_1='%s',"..
                "  c_args_2='%s',"..
                "  c_args_3='%s',"..
                "  c_args_4='%s',"..
                " where id = '%s' ",
                millisec, api, args_1, args_2, args_3, args_4, id
            );
        executeUpdate(sql);
    else
        logger.notice('timeout[', id, "] existed and has't been executed, don't change DB state");
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
            " select id, c_api as cmd, -1 as timeout, 'timeout' as type, "..
            " c_args_1, c_args_2, c_args_3, c_args_4 "..
            " from t_task_timeout where n_executed = 2 and d_execute <= now() "..
            "union all"..
            " select id, c_api as cmd, n_timeout as timeout, 'interval' as type, "..
            " c_args_1, c_args_2, c_args_3, c_args_4 "..
            " from t_task_interval where d_execute <= now() "
        );

    local key;
    local cmd;
    local tasks = {};
    executeQuery(sql, function(row)
        row['timeout'] = tonumber(row['timeout']);
        row['args'] = {};
        table.insert(row['args'], row['c_args_1']);
        table.insert(row['args'], row['c_args_2']);
        table.insert(row['args'], row['c_args_3']);
        table.insert(row['args'], row['c_args_4']);
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
            "insert into t_task_interval (id, d_created, d_execute, n_timeout, c_api)"..
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
