require('libs.db');
require('libs.commons');

function saveRegistrationExt(call_id, profile, user_id, user_agent, realm, local_host, contact, expires)
    local sql;
    sql = sqlstring.format("delete from t_registration_ext where user_id='%s'", user_id);
    executeUpdate(sql);

    sql = sqlstring.format(
            "insert into t_registration_ext "..
            "  (call_id, profile, user_id, user_agent, realm, local_host, contact, expires, expired, created) "..
            "values ('%s', '%s', '%s', '%s', '%s','%s', '%s', %s, now() + interval '%s' second, now())",
                call_id, profile, user_id, user_agent, realm, local_host, contact, expires, expires
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
    sql = "delete from t_registration_ext where expired < now()";
    --executeUpdate(sql);
end;

function saveOrUpdateUser(id, phone, name, pass)
    if nil == pass then pass = '1234'; end;

    -- it's no use to save DB, so do nothing
    local log = string.format("%s login, and use passwd '%s', name = %s\n", phone, pass, name);
    freeswitch.consoleLog('notice', log);

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


