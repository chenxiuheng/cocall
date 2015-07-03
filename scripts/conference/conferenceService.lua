require('libs.db');
require('libs.commons');
require('task.taskService');

function isTrue(value) 
    if (nil == value or '' == value) then return false; end;
    if (2 == value or '2' == value) then  return false; end;
    if (false == value or 'false' == value) then  return false; end;

    return true;
end;

function isFalse(value) 
    if isTrue(value) then return false end;

    return true;
end;

function boolean (value)
    if 1 == value then return true end;
    
    return false;
end;


---------------   Conference DAO ---------------------------------------------
function getConferenceMembers(confPhone, user, except)
    local sql;

    local buf = newSqlBuilder();
   
    buf.append(" SELECT DISTINCT ");
    buf.append(" mem.c_phone_no  as user, ");
    buf.append(" mem.c_name      as name, ");
    buf.append(" mem.n_is_in as is_in, ");
    buf.append(" mem.c_member_type as type, ");
    buf.append(" mem.n_member_id as member_id, ");
    buf.append(" mem.n_can_speak as can_speak, ");
    buf.append(" (select count(*) from t_registration_ext as ext  where ext.user_id=mem.c_phone_no and expired > now()) as num_reg, ");
    buf.append(" mem.n_is_moderator as is_moderator ");
    buf.append(" FROM ");
    buf.append(" t_conference_member AS mem ");
    buf.format(" where mem.c_conference_phone_no = '%s' ", confPhone);


    if 'non_moderator' == user then 
        buf.append("  and n_is_moderator <> 1");
    elseif 'moderator' == user then
        buf.append("  and n_is_moderator = 1");
    elseif 'all' ~= user and nil ~= user then
        buf.format(" AND mem.c_phone_no='%s'", user);
    end;

    if 'non_moderator' == except then 
        buf.append(" and n_is_moderator = 1");
    elseif 'moderator' == except then
        buf.append(" and n_is_moderator <> 1");
    elseif nil ~= except then
        buf.format(" AND mem.c_phone_no<>'%s'", except);
    end;

    local members = {};
    executeQuery(buf.toString(), function(row)
        if row['num_reg'] == '0' then
            row['is_online'] = '2';
        else
            row['is_online'] = '1';
        end;

        table.insert(members, row);
    end);

    return members;
end;


function updateConferenceMemberFields(confPhone, user, field, value)
    local buf = newSqlBuilder("update t_conference_member ");

    local isVarchar = nil ~= string.match(field, "^[cC].*$");
    if isVarchar then
        buf.append(" set ").append(field).format("='%s'", value);
    else    
        buf.append(" set ").append(field).format("=%s", value);
    end;

    buf.format(" where c_conference_phone_no = '%s' ", confPhone);

    if 'non_moderator' == user then
        buf.append("  and n_is_moderator <> 1 ");
    elseif nil ~= user then
        buf.format("  and c_phone_no = '%s' ", user);
    end;

    return buf.update();
end;

local CONFERENCE_MEMBER_ENERGY_EXPIRSED = 1000;

function getConferenceMemberEnergies (confPhone)
    local buf = newSqlBuilder();

    buf.append("select c_phone_no as user, ");
    buf.append("    n_cur_engery as cur_energy, ");
    buf.append("    n_engery_level as energy_level");
    buf.append(" from t_conference_member");
    buf.append("  where c_conference_phone_no = '%s' ", confPhone);
    buf.append("  and now() - d_speak < interval '%s millisecond'", CONFERENCE_MEMBER_ENERGY_EXPIRSED);
    buf.append(" and n_engery_level is not null");
    buf.append(" and n_cur_engery > 0 ");

    return buf.list();
end;

function updateConferenceMemberEnergy(confPhone, user, energy, energy_level)
    if nil == energy_level or 'nil' == energy_level or '' == energy_level then
        energy_level = 300;
    end;


    local sql;
    sql = sqlstring.format(
            "update t_conference_member set n_is_in = 1, d_speak = now(), n_cur_engery = %s, n_engery_level = %s "..
            " where c_conference_phone_no = '%s' and c_phone_no = '%s'",
            energy, energy_level, confPhone, user
        );
    
    executeUpdate(sql);
end;


function setConferenceModerator(confPhone, user)
    local sql;
    sql = sqlstring.format(
            "update t_conference set c_moderator_phone_no='%s' where c_phone_no='%s' ",
            user, confPhone
        );
    executeUpdate(sql);
    
    sql = sqlstring.format(
            "update t_conference_member set n_is_moderator = (case when c_phone_no = '%s' then 1 else 2 end)  "..
            " where c_conference_phone_no='%s'",
            user, confPhone
        );
    executeUpdate(sql);
end;

function setConferenceName(confPhone, newName)
    local sql;
    sql = sqlstring.format(
            "update t_conference set c_name='%s' where c_phone_no='%s'  ",
            newName, confPhone
        );
    
    executeUpdate(sql);
end;

function setConferenceMemberIn (confPhone, user, memberId)
    local sql;
    local last_member_id;
    local is_moderator = false

    if nil ~= user then 
        --1, find last member_id;
        sql = sqlstring.format(
                "select n_member_id, n_is_moderator from t_conference_member where "..
                " c_conference_phone_no='%s' and c_phone_no='%s' ",
                confPhone, user
            );
        local rowCount = executeQuery(sql, function(row)
            last_member_id = row['n_member_id'];
            is_moderator = isTrue(row['n_is_moderator']);
        end);

        --2, update and set new member_id
        if (rowCount > 0) then
            sql = sqlstring.format(
                    "update t_conference_member set n_is_in=1, n_member_id=%s "..
                    " where c_conference_phone_no = '%s' and c_phone_no='%s' ",
                    memberId, confPhone, user
                ); 

            executeUpdate(sql);
        end;
    end;

    return last_member_id, is_moderator;
end;

function setConferenceMemberOut(confPhone, user, memberId)
    newSqlBuilder(" update t_conference_member set n_is_in=2, n_has_video=2, d_speak = null, n_member_id = null ")
          .append(" where c_conference_phone_no='%s'", confPhone)
          .append(" and c_phone_no='%s'", user)
          .append(" and n_member_id=%s", memberId)
          .update();
end;


-- created conference    
function createConference (name, creator, creatorName)
    local phoneNo = nil;


    executeQuery("BEGIN");
    executeQuery("LOCK TABLE t_id IN ACCESS EXCLUSIVE MODE");
    executeQuery(
            "select next_id('conf') as id", function(row)
        phoneNo = row['id']
    end);
    executeQuery("COMMIT");


    newSqlBuilder(" insert into t_conference  ")
          .append(" (c_phone_no, c_moderator_phone_no, c_name, c_creator, c_creator_name," )
          .append(" d_created, d_updated, d_plan, n_valid, c_profile,  n_is_running)")
          .append(" values ")
          .format(" ('%s'", phoneNo)
          .format(" ,'%s'", creator)
          .format(" ,'%s'", name)
          .format(" ,'%s'", creator)
          .format(" ,'%s'", creatorName)
          .append(" ,now(),  now(), now(), 1, 'default', 2")
          .append(" )")
          .update();

    return phoneNo;
end;

function setConferenceIsRunning(confPhone, n_is_running)
    local sql;
    sql = sqlstring.format("update t_conference set n_is_running =%s, d_created = now() where c_phone_no='%s'",
            n_is_running,
            confPhone
        );
    executeUpdate(sql);

    -- not running
    if 1 ~= n_is_running then
        newSqlBuilder(" update t_conference_member set n_is_in=2, n_has_video=2, d_speak = null, n_member_id = null ")
              .append(" where c_conference_phone_no='%s'", confPhone)
              .update();
    end;
end;

function getConferenceInfo(confPhone)
    local buf = newSqlBuilder();

    buf.append(" SELECT ");
    buf.append(" conf.c_phone_no as conference,  ");
    buf.append(" conf.c_name as name,  ");
    buf.append(" conf.c_moderator_phone_no as moderator,  ");
    buf.append(" conf.c_creator as creator,  ");
    buf.append(" conf.c_creator_name as creator_name,  ");
    buf.append(" conf.n_valid as valid,  ");
    buf.append(" to_char(conf.d_created, 'YYYY:MM:DD HH24:MI:SS') as created, ");
    buf.append(" conf.c_profile  ");
    buf.append(" FROM  ");
    buf.append("    t_conference AS conf  ");
    buf.append(" where  conf.c_phone_no='%s' ", confPhone);

    -- get row    
    return buf.list()[1];
end;

-- get conferences of User
function getMyConferences (memberPhone, runningOnly)
    local extraSql = "";
    if nil ~= runningOnly and runningOnly then extraSql = " and n_is_running = 1 " ;end;

    local buf = newSqlBuilder();
    
    buf.append(" SELECT ");
    buf.append(" conf.c_phone_no as conference, ");
    buf.append(" conf.c_name as name, ");
    buf.append(" conf.c_moderator_phone_no as moderator, ");
    buf.append(" conf.c_creator as creator, ");
    buf.append(" conf.c_creator_name as creator_name, ");
    buf.append(" conf.c_profile, ");
    buf.append(" conf.n_valid as valid, ");
    buf.append(" to_char(conf.d_created, 'YYYY:MM:DD HH24:MI:SS') as created,");
    buf.append(" (select count(*) from t_conference_member where c_conference_phone_no=conf.c_phone_no) as num_member, ");
    buf.append(" (select count(*) from t_conference_member where c_conference_phone_no=conf.c_phone_no and n_is_in = 1) as num_is_in ");
    buf.append(" FROM ");
    buf.append("    t_conference AS conf ");
    buf.append(" where  n_valid=1 ");
    buf.append(extraSql);
    buf.append(" and EXISTS ( ");
    buf.append("     SELECT c_conference_phone_no from t_conference_member  ");
    buf.append("     where c_conference_phone_no = conf.c_phone_no");
    buf.append("       and c_phone_no = '%s' ", memberPhone);
    buf.append(") ");
    buf.append(" order by d_created desc ");

    return buf.list();
end;

function clearInvalidConferences()
    -- clear
    newSqlBuilder()
        .append(" delete from t_conference_old where c_phone_no in ")
        .append(" (select c_phone_no from t_conference)")
        .update();

    
    -- copy
    newSqlBuilder()
        .append(" INSERT INTO t_conference_old( ")
        .append("   c_phone_no, c_moderator_phone_no, c_name,d_created,")
        .append("   d_plan,n_valid,d_started,c_unique_id,c_profile,c_creator,")
        .append("   c_creator_name,n_is_running,d_updated,n_updated")
        .append(" ) SELECT ")
        .append("   c_phone_no, c_moderator_phone_no, c_name,d_created,")
        .append("   d_plan,n_valid,d_started,c_unique_id,c_profile,c_creator,")
        .append("   c_creator_name,n_is_running,d_updated,n_updated")
        .append(" FROM t_conference")
        .append(" WHERE n_valid = 2")
        .update();
    
    -- delete repeated
    newSqlBuilder()
        .append(" delete from t_conference ")
        .append(" WHERE n_valid = 2 and EXISTS ")
        .append(" (select o.c_phone_no from t_conference_old o where o.c_phone_no = c_phone_no)")
        .update();
end;

-----// END   Conference DAO ---------------------------------------------


-- API for conference
function newConferenceService(confPhone)
    local logger = getLogger('conferenceS['..confPhone..']');

    local info = nil;
    local service = {};

    function getInfo()
        if nil == info then info = getConferenceInfo(confPhone); end;
        return info;
    end;
    function releaseInfo()
        info = nil;
    end;

    function dispatchSMS(members, msg)
        local to_users = {};
        for i, member in ipairs(members) do
            local is_in = member['is_in'];
            local user = member['user'];
            if isTrue(is_in)  then
                table.insert(to_users, user);
            end;
        end;

        batchSendSMS(confPhone, to_users, msg);
    end;



    service.getPhoneNo = function()
        return confPhone;
    end;

    service.getInfo = function()
        return getInfo();
    end;

    service.getName = function()
        local info = getInfo();

        if nil ~= info then return info['name'] end;
        return nil;
    end;

    service.setName = function (new_name)
        if nil == new_name or "" == new_name then
            logger.info('empty name[', new_name, '], ignore it');
            return false; 
        end;

        if nil ~= info and info['name'] == new_name then
            logger.info('same name[', new_name, '], ignore it');
            return false; 
        end;

        setConferenceName(confPhone, new_name);
        releaseInfo();
        return true;
    end;

    service.getCreator = function()
        local info = getInfo();

        if nil ~= info then return info['creator'] end;
        return nil;
    end;

    service.getCreatorName = function()
        local info = getInfo();

        if nil ~= info then return info['creator_name'] end;
        return nil;
    end;


    service.getModerator = function()
        local info = getInfo();

        if nil ~= info then return info['moderator'] end;
        return nil;
    end;

    service.setIsRunning = function (isRunning)
        local n_is_running = 2;
        if isRunning then
            n_is_running = 1;
        end;

        setConferenceIsRunning(confPhone, n_is_running);
        releaseInfo();
    end;

    service.addMember=function(member, fastInsert)
        local user = member['user'];
        local name = member['name'];

        -- check exists
        if nil == fastInsert or not fastInsert then
            local existed = false;
            newSqlBuilder(" select count(*) num from t_conference_member")
                .append("   where c_conference_phone_no = '%s'", confPhone)
                .append("   and c_phone_no = '%s'", user)
                .query(function(row)
                    if row['num'] ~= '0' then existed = true end;
                end);
            if existed then
                return false;
            end;
        end;

        -- save to DB        
        newSqlBuilder("insert into t_conference_member ")
            .append(" ( c_conference_phone_no, c_phone_no, c_name, d_created, n_is_moderator, n_can_hear, n_can_speak) ")
            .append(" values ")
            .format("( '%s'", confPhone)
            .format(", '%s'", user)
            .format(", '%s'", name)
            .append(", now()")
            .append(", 2")
            .append(", 1")
            .append(", 1")
            .append(") ")
            .update();

        return true;
    end;
    
    service.getMembers = function(user, except) 
        return getConferenceMembers(confPhone, user, except);
    end;
    

    service.removeMember = function(user)
        local sql;
        local numDeleted = 0;
        local numSum = 0;
        
        -- WARNING: 
        -- can't call confernce XXX kick member_id maybe cause deadlock


        -- delete from db
        numDeleted = newSqlBuilder(" delete from t_conference_member ")
                      .format(" where c_conference_phone_no = '%s' ", confPhone)
                      .format(" AND c_phone_no = '%s'", user)
                      .update();

        -- if only one member, set him as moderator
        if (numSum - numDeleted == 1) then
            newSqlBuilder(" update t_conference_member ")
              .append(" set n_is_moderator = 1")
              .format(" where c_conference_phone_no = '%s' ", confPhone)
              .format(" AND 1 = (select count(*) from t_conference_member as mem where mem.c_conference_phone_no = '%s')", confPhone)
              .update();

            newSqlBuilder(" update t_conference ")
              .append(" set c_moderator_phone_no = ")
              .append(" (select c_phone_no from t_conference_member as mem ")
              .format("  where mem.n_is_moderator = 1 and mem.c_conference_phone_no = '%s'", confPhone)
              .append(" )")
              .format(" where c_phone_no = '%s' ", confPhone)
              .update();
        end;

        releaseInfo();
    end;

    service.destroy = function ()
        -- set conference invalid
        local sql;
        sql = sqlstring.format(
               "update t_conference set n_valid = 2 where c_phone_no='%s'",
                confPhone
            );
        executeUpdate(sql);

        releaseInfo();
    end;

    service.mute = function(user)
        local sql;
        local non_moderator = false;

        local members;
        if user == 'non_moderator' then
            members = getConferenceMembers(confPhone);
            non_moderator = true;
        else 
            members = getConferenceMembers(confPhone, user);
        end;

        -- update DB state
        updateConferenceMemberFields(confPhone, user, 'n_can_speak', '2');

        -- update
        for i, member in ipairs(members) do
            local memberId = member['member_id'];
            local is_in = member['is_in'];
            local is_moderator = isTrue(member['is_moderator']);

            if non_moderator and is_moderator then
                    -- ignore because current is moderator but he want to mute non_moderator
            else
                if isTrue(is_in) then
                    freeswitch.API():execute('conference', confPhone ..' mute '.. memberId);
                end;
            end;
        end;
        
        releaseInfo();
    end;

    service.unmute = function(user)
        local sql;
        local non_moderator = false;

        local members;
        if user == 'non_moderator' then
            members = getConferenceMembers(confPhone);
            non_moderator = true;
        else 
            members = getConferenceMembers(confPhone, user);
        end;

        -- update DB state
        updateConferenceMemberFields(confPhone, user, 'n_can_speak', '1');

        -- update
        for i, member in ipairs(members) do
            local memberId = member['member_id'];
            local is_in = member['is_in'];
            local is_moderator = member['is_c'];

            if non_moderator and is_moderator then
                    -- ignore because current is moderator but he want to unmute non_moderator
            else
                if isTrue(is_in) then
                    freeswitch.API():execute('conference', confPhone ..' unmute '.. memberId);
                end;
            end;
        end;

        releaseInfo();
    end;

    service.changeVideoFloor = function(user)
        local moderator_is_in = false;

        -- moderator is in, set vid-floor
        local members = service.getMembers('moderator');
        for i, member in ipairs(members) do
            local is_in = member['is_in'];
            local member_id = member['member_id'];

            if user == member['user'] then
                freeswitch.API():execute('conference', service.getPhoneNo()..' vid-floor '..member_id ..' force');
                logger.info("user[", user , "] is moderator set vid-floor force & return;");
                return true;
            end;

            if isTrue(is_in) then
                moderator_is_in = true;
            end;
        end;

        -- moderator NOT in, set vid-floor
        if not moderator_is_in then
            members = service.getMembers(user);
            for i, member in ipairs(members) do
                local is_in = member['is_in'];
                local member_id = member['member_id'];
                
                if isTrue(is_in) then
                    freeswitch.API():execute('conference', service.getPhoneNo()..' vid-floor '..member_id ..' force');
                    logger.warn("moderator is NOT in conference, user[", user , "] has been setted vid-floor force & return;");
                    return true;
                end;
            end;
        end;

        -- do nothing
        logger.warn("something wrong, ignore set vid-floor for user[", user , "] & return;");
        return false;
    end;

    service.setModerator = function(user)
        local sql;
        
        -- update DB
        sql = sqlstring.format(
                "update t_conference set c_moderator_phone_no='%s' where c_phone_no='%s' ",
                user, confPhone
            );
        executeUpdate(sql);

        sql = sqlstring.format(
                "update t_conference_member set n_is_moderator = (case when c_phone_no = '%s' then 1 else 2 end) where c_conference_phone_no='%s' ",
                user, confPhone
            );
        executeUpdate(sql);


        -- change switch
        local members = service.getMembers('moderator');
        for i, member in ipairs(members) do
            local is_in = member['is_in'];
            local member_id = member['member_id'];

            freeswitch.API():execute('conference', service.getPhoneNo()..' vid-floor '..member_id ..' force');
            logger.warn('conference', service.getPhoneNo(), "set member", member_id , " vid-floor");
        end;

        releaseInfo();
    end;

    service.dispatchMemberEnergies = function ()
        local noEnergyInfo = true;

        local buf = newStringBuilder('conference-energy');
        local energies = getConferenceMemberEnergies(confPhone);
        for i, energy in ipairs(energies) do
            noEnergyInfo = false;

            buf.append('\n');
            buf.append(energy['user']).append(';').append(energy['cur_energy']).append('/').append(energy['energy_level']);
        end;
        buf.append('\n');

        if noEnergyInfo then
            logger.debug('No member energies to dispatch');
        else
            local members = getConferenceMembers(confPhone);
            dispatchSMS(members, buf.toString());
        end;
    end;


    function formatAsSMS(members)

        local oct_to_hex = {}
        oct_to_hex[0] = '0';
        oct_to_hex[1] = '1';
        oct_to_hex[2] = '2';
        oct_to_hex[3] = '3';
        oct_to_hex[4] = '4';
        oct_to_hex[5] = '5';
        oct_to_hex[6] = '6';
        oct_to_hex[7] = '7';
        oct_to_hex[8] = '8';
        oct_to_hex[9] = '9';
        oct_to_hex[10] = 'A';
        oct_to_hex[11] = 'B';
        oct_to_hex[12] = 'C';
        oct_to_hex[13] = 'D';
        oct_to_hex[14] = 'E';
        oct_to_hex[15] = 'F';

        local buf = newStringBuilder('conference-members');
        for i, member in ipairs(members) do
            local user = member['user'];
            local name = member['name'];
            local is_online = member['is_online'];
            local is_in = member['is_in'];
            local can_speak = member['can_speak'];
            local is_moderator = member['is_moderator'];
            
            local flags = 0;

            --  'online';
            if isTrue(is_online) then flags = flags + 8; end;

            -- isInConference;
            if isTrue(is_in) then flags = flags + 4; end;

            -- unmute
            if isTrue(can_speak) then flags = flags + 2; end;

            -- is_moderator
            if isTrue(is_moderator) then flags = flags + 1;end;
          
            buf.append('\n');
            buf.append(user).append(';').append(name).append(';').append(oct_to_hex[flags]).append(';');
        end;
        buf.append('\n');

        return buf.toString();
    end;

    service.getMemberStates = function (dstUser)
        -- 1, get member's states
        local members;
        members = getConferenceMembers(confPhone);
        
        -- 2, build msg
        local msg = formatAsSMS(members);

        -- 3. send to the user
        sendSMS(confPhone, dstUser, msg);
    end;

    service.dispatchMemberStates = function ()

        -- 1, get member's states
        local members;
        members = getConferenceMembers(confPhone);
        
        -- 2, build msg
        local msg = formatAsSMS(members);

        dispatchSMS(members, msg);
    end;


    service.notifyAll = function () 
        local id = string.format("conference/%s/member-list", confPhone);
        local cmd = string.format("api_dispatch_member_list %s", confPhone);
        setTimeoutIfAbsent(id, cmd, 700);
    end;

    service.toSimpleString = function() 
        return formatConference(getInfo());
    end;

    service.sayTo = function(dstUser, from_user, arg0, arg1, arg2, arg3, arg4, arg5)
        function v (arg)
            if nil == arg then return ''; else return arg; end;
        end;

        local members = service.getMembers(dstUsers, from_user); -- except myself
        
        local msg = '';
        if     nil ~= arg5 then msg = string.format('%s\n%s\n%s\n%s\ns\ns\n', v(arg0), v(arg1), v(arg2), v(arg3), v(arg4), v(arg5));
        elseif nil ~= arg4 then msg = string.format('%s\n%s\n%s\n%s\ns\n',    v(arg0), v(arg1), v(arg2), v(arg3), v(arg4));
        elseif nil ~= arg3 then msg = string.format('%s\n%s\n%s\n%s\n',       v(arg0), v(arg1), v(arg2), v(arg3));
        elseif nil ~= arg2 then msg = string.format('%s\n%s\n%s\n',           v(arg0), v(arg1), v(arg2));
        elseif nil ~= arg1 then msg = string.format('%s\n%s\n',               v(arg0), v(arg1));
        elseif nil ~= arg0 then msg = string.format('%s\n',                   v(arg0));
        else msg ='\n';
        end;

        return dispatchSMS(members, msg);
    end;

    return service;
end;

function formatConference(info)
    if nil == info then return ''; end;
    
    return string.format('%s;%s;%s;%s;', info['name'], info['creator'], info['creator_name'], info['created']);

end;


