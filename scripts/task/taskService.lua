
function setTimeout(cmd, millisec, id)
    local sql;
    if nil == id then id = 'auto_'..cmd; end;

    -- delete task with same id
    sql = sqlstring.format(
            "delete from t_task where id='%'",
            id
        );
    executeUpdate(sql);
    
    -- insert task db row
    sql = sqlstring.format(
            "insert into t_task (id, d_created, n_executed, d_execute, c_lua_cmd)"..
            "values ('%s', now(), 2, now() + interval '%s millisecond', '%s')",
            id, millisec, cmd
        );
    executeUpdate(sql);

    return id;
end;


function clearTimeout(id)
    local sql;
    sql = sqlstring.format(
            "update t_task set n_executed = 1 where id='%'",
            id
        );
    executeUpdate(sql);
end;

function getUnexecutedTask()
    local sql;
    sql = sqlstring.format(
            "select id, c_lua_cmd as cmd from t_task where n_executed = 2 and d_execute >= now() "
        );

    local key;
    local cmd;
    local tasks = {};
    executeQuery(sql, function(row)
        key = row['id'];
        cmd = row['cmd'];
        tasks[key] = row['cmd'];
    end);

    return tasks;
end;
