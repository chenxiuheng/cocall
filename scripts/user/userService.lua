
function saveRegistrationExt(call_id, profile, user_id, user_agent, realm, contact, expires)
    local sql;
    sql = sqlstring.format("delete from t_registration_ext where call_id='%s'", call_id);
    executeUpdate(sql);

    sql = sqlstring.format(
            "insert into t_registration_ext "..
            "  (call_id, profile, user_id, user_agent, realm, contact, expires, expired, created) "..
            "values ('%s', '%s', '%s', '%s', '%s', '%s', %s, now() + interval '%s' second, now())",
                call_id, profile, user_id, user_agent, realm, contact, expires, expires
        );
    executeUpdate(sql);
end;

function deleteRegistrationExt(call_id)
    local sql;
    sql = sqlstring.format("delete from t_registration_ext where call_id='%s'", call_id);
    executeUpdate(sql);
end;

function deleteRegistrationExtOutOfDate()
    local sql;
    sql = sqlstring.format("delete from t_registration_ext where expired < now()");
    executeUpdate(sql);
end;

function saveOrUpdateUser(id, phone, name, pass)
    local sql;
    sql = string.format("select c_id from t_user where c_id = '%s' ", id);

    -- use default pass
    if (nil == pass) then pass = '1234'; end;
    
    -- use default name
    if (nil == name) then name = id; end;

    local numRows = executeQuery(sql);

    -- insert if not found
    if numRows  == 0 then
        sql = string.format('insert into t_user (c_id, c_phone_no, c_name, c_passwd, n_is_online, d_login)'..
                " values ('%s', '%s', '%s', '%s', %s, now())",
                id, id, name, pass, 1);
        executeUpdate(sql);
    end;

    -- or update login state
    if (numRows > 0) and (nil ~= name) then
         sql = string.format("update t_user set c_name='%s', c_passwd='%s', n_is_online=%s, d_login=now() where c_id='%s'",
                name, pass, 1, id
            );
        executeUpdate(sql);
    end;

    return pass;
end;


function getUser(user)
    local sql;
    sql = string.format(
            " SELECT c_name as user, c_passwd as passwd, c_realm as realm"..
            " from t_user where c_phone_no='%s'",
            user
        );

    local selected = nil;    
    executeQuery(sql, function(row)
        selected = row;
        selected['from_full'] = 'sip'..row['user']..'@'..row['realm']
    end);

    return selected;
end;


