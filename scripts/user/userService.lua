
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

function userLogout(user, token)
    local sql;
    sql = string.format(
            "delete from registrations where token='%s' and reg_user='%s'",
            token, user
        ); 

    executeUpdate(sql);
end;
