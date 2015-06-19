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

    sql = sqlstring.format(
        " SELECT DISTINCT "..
        " mem.c_phone_no  as user, "..
        " mem.c_name      as name, "..
        " mem.n_is_in as is_in, "..
        " mem.c_member_type as type, "..
        " mem.n_member_id as member_id, "..
        " mem.n_can_speak as can_speak, "..
        " (select count(*) from t_registration_ext as ext  where ext.user_id=mem.c_phone_no and expired > now()) as num_reg, "..
        " mem.n_is_modirator as is_moderator "..
        " FROM "..
        " t_conference_member AS mem "..
        " where mem.c_conference_phone_no = '%s' ",
        confPhone
    );

    if 'non_moderator' == user then 
        sql = sql .. "  and n_is_modirator <> 1";
    elseif 'moderator' == user then
        sql = sql .. "  and n_is_modirator = 1";
    elseif 'all' ~= user and nil ~= user then
        sql = sql .. sqlstring.format(" AND mem.c_phone_no='%s'", user);
    end;

    if 'non_moderator' == except then 
        sql = sql .. "  and n_is_modirator = 1";
    elseif 'moderator' == except then
        sql = sql .. "  and n_is_modirator <> 1";
    elseif nil ~= except then
        sql = sql .. sqlstring.format(" AND mem.c_phone_no<>'%s'", except);
    end;

    local memberIndex = 1;    
    local members = {};
    executeQuery(sql, function(row)
        if row['num_reg'] == '0' then
            row['is_online'] = '2';
        else
            row['is_online'] = '1';
        end;

        members[memberIndex] = row;
        memberIndex = memberIndex + 1;
    end);

    return members;
end;


function updateConferenceMemberFields(confPhone, user, field, value)
    local sql = "update t_conference_member ";

    local isVarchar = nil ~= string.match(field, "^[cC].*$");
    if isVarchar then
        sql = sql .. " set " .. field .. sqlstring.format("='%s'", value);
    else    
        sql = sql .. " set " .. field .. sqlstring.format("=%s", value);
    end;

    sql = sql .. sqlstring.format(" where c_conference_phone_no = '%s' ", confPhone);

    if 'non_moderator' == user then
        sql = sql .. "  and n_is_modirator <> 1 ";
    elseif nil ~= user then
        sql = sql .. sqlstring.format("  and c_phone_no = '%s' ", user);
    end;

    executeUpdate(sql);
end;

local CONFERENCE_MEMBER_ENERGY_EXPIRSED = 1000;

function getConferenceMemberEnergies (confPhone)
    local sql;
    sql = sqlstring.format(
            "select c_phone_no as user, "..
            "       n_cur_engery as cur_energy, "..
            "       n_engery_level as energy_level"..
            " from t_conference_member"..
            "  where c_conference_phone_no = '%s'  and now() - d_speak < interval '%s millisecond'"..
            " and n_engery_level is not null",
            confPhone, CONFERENCE_MEMBER_ENERGY_EXPIRSED
        );

    local rows = {};
    executeQuery(sql, function(row)
        table.insert(rows, row);
    end);

    return rows;
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
            "update t_conference set c_modirator_phone_no='%s' where c_phone_no='%s' ",
            user, confPhone
        );
    executeUpdate(sql);
    
    sql = sqlstring.format(
            "update t_conference_member set n_is_modirator = (case when c_phone_no = '%s' then 1 else 2 end)  "..
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
    local is_modirator = false

    if nil ~= user then 
        --1, find last member_id;
        sql = sqlstring.format(
                "select n_member_id, n_is_modirator from t_conference_member where "..
                " c_conference_phone_no='%s' and c_phone_no='%s' ",
                confPhone, user
            );
        local rowCount = executeQuery(sql, function(row)
            last_member_id = row['n_member_id'];
            is_modirator = isTrue(row['n_is_modirator']);
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

    return last_member_id, is_modirator;
end;

function setConferenceMemberOut(confPhone, user, memberId)
    local sql;

    -- 1, update DB state, the member must be last used.
    --     if the member id in DB is not eq memberId arg, do nothing
    sql = sqlstring.format(
        " update t_conference_member set n_is_in=2, n_has_video=2 "..   
        " where c_conference_phone_no='%s' and c_phone_no='%s'  and n_member_id=%s",
        confPhone, user, memberId
    );
    executeUpdate(sql);

end;


-- created conference    
function createConference (name, creator, creatorName)
    local phoneNo = nil;

    -- 1, get Next Conference Phone Number
    executeQuery("select next_phone_no('conf') num", function(row) 
        phoneNo = row.num;
    end);

    assert(phoneNo, "T_Phone have NOT config for 'conf'");

    -- 2, insert row data
    local sql = sqlstring.format(
            'insert into t_conference  '..
            ' (c_phone_no, c_modirator_phone_no, c_name, c_creator, c_creator_name, d_created, d_updated, d_plan, n_valid, c_profile,  n_is_running)'..
            "values ('%s', '%s', '%s', '%s', '%s', now(),  now(), now(), 1, 'default', 2)",
            phoneNo, creator, name, creator, creatorName
        );
    executeUpdate(sql);

    -- 3, return conf phone no
    return phoneNo;
end;

function setConferenceIsRunning(confPhone, n_is_running)
    local sql;
    sql = sqlstring.format("update t_conference set n_is_running =%s, d_created = now() where c_phone_no='%s'",
            n_is_running,
            confPhone
        );
    executeUpdate(sql);
end;

function getConferenceInfo(confPhone)
    local sql = sqlstring.format(
        ' SELECT '..
        ' conf.c_phone_no as conference, '..
        ' conf.c_name as name, '..
        ' conf.c_modirator_phone_no as moderator, '..
        ' conf.c_creator as creator, '..
        ' conf.c_creator_name as creator_name, '..
        ' conf.n_valid as valid, '..
        ' (extract(epoch from now()) - extract(epoch from d_created)) as age,'..
        ' conf.c_profile '..
        ' FROM '..
        '    t_conference AS conf '..
        " where  conf.c_phone_no='%s' ",
        confPhone
    );

    -- get row    
    local info;
    executeQuery(sql, function(row)
        info = row;
    end);

    return info;
end;

-- get conferences of User
function getMyConferences (memberPhone, runningOnly)
    local extraSql = "";
    if nil ~= runningOnly and runningOnly then extraSql = " and n_is_running = 1 " ;end;

    local sql = sqlstring.format(
            ' SELECT '..
            ' conf.c_phone_no as conference, '..
            ' conf.c_name as name, '..
            ' conf.c_modirator_phone_no as moderator, '..
            ' conf.c_creator as creator, '..
            ' conf.c_creator_name as creator_name, '..
            ' conf.c_profile, '..
            ' conf.n_valid as valid, '..
            '  (extract(epoch from now()) - extract(epoch from d_created)) as age,'..
            ' (select count(*) from t_conference_member where c_conference_phone_no=conf.c_phone_no) as num_member, '..
            ' (select count(*) from t_conference_member where c_conference_phone_no=conf.c_phone_no and n_is_in = 1) as num_is_in '..
            ' FROM '..
            '    t_conference AS conf '..
            ' where  n_valid=1 '..
            ' %s ' ..
            ' and conf.c_phone_no in ( '..
            "     SELECT c_conference_phone_no from t_conference_member where c_phone_no = '%s' "..
            ") " ..
            " order by d_created desc ",
            extraSql, memberPhone
        );

    local confIndex = 1;
    local confs = {};
    executeQuery(sql, function(row)
        confs[confIndex] = row;
        
        confIndex = confIndex + 1;
    end);
    
    return confs;
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

    service.addMember=function(member, firstInsert)
        local uuid = confPhone..'.'..member['user'];
        local user = member['user'];
        local name = member['name'];

        -- check it existed
        local sql;
        local existed = false;
        if nil ~= firstInsert and firstInsert then
            sql = sqlstring.format(
                    "select count(*) num from t_conference_member where c_conference_phone_no = '%s' and c_phone_no = '%s'",
                    confPhone, user
                );
            executeQuery(sql, function(row)
                if row['num'] ~= '0' then existed = true end;
            end);

            if existed then return true; end; -- existed, do nothing
        end;
        

        local info = getInfo();
        if nil == info then return false; end; -- NO conference found
        if not isTrue(info['valid']) then 
            logger.warn("can't add-member in invalid conference[", confPhone, ']');
            return false; 
        end; -- not valid

        -- insert into DB if not existed
        local isModerator =  2;
        if member['user'] == info['moderator'] then isModerator = 1 end;

        sql = sqlstring.format(
                'insert into t_conference_member '..
                "   (c_id, c_conference_phone_no, c_phone_no, c_name, d_created, n_is_modirator, n_can_hear, n_can_speak)"..
                " values "..
                "   ('%s', '%s', '%s', '%s', now(), '%s', %s, %s) ",
                uuid, confPhone, user, name, isModerator, 1, 1
            );

        -- save creator as a member of conference
        executeUpdate(sql);              

        return true;
    end;
    
    service.getMembers = function(user, except) 
        return getConferenceMembers(confPhone, user, except);
    end;
    

    service.kick = function(user, operator)
        local sql;
        
        -- kick from swtich
        local members = getConferenceMembers(confPhone, user);
        for i, member in ipairs(members) do
            local member_id    = member['member_id'];
            if isTrue(member['is_in']) and nil ~= member_id then
                freeswitch.API():execute('conference', confPhone..' kick '.. member_id);
                logger.info('kick ', member['user'], 'from conference[', confPhone, '] member-id=', member_id);
                sendSMS(confPhone, member['user'], 'conference-kicked', 'you are kick by ' .. operator);
            end;
        end;

        -- delete from db
        sql = sqlstring.format(
                " delete from t_conference_member "..
                " where c_conference_phone_no = '%s' "..
                "   AND c_phone_no = '%s'",
                 confPhone, user
            );
        executeUpdate(sql);

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

        -- kick from swtich
        local is_in;
        local memberId;
        local members = getConferenceMembers(confPhone);
        for i, member in ipairs(members) do
            is_in = member['is_in'];
            memberId = member['member_id'];
            freeswitch.API():execute('conference', confPhone ..' kick '.. memberId);
        end;

        dispatchSMS(members, 'conference-destroy');

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
                "update t_conference set c_modirator_phone_no='%s' where c_phone_no='%s' ",
                user, confPhone
            );
        executeUpdate(sql);

        sql = sqlstring.format(
                "update t_conference_member set n_is_modirator = (case when c_phone_no = '%s' then 1 else 2 end) where c_conference_phone_no='%s' ",
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
        local energy_msg = 'conference-energy';
        local energies = getConferenceMemberEnergies(confPhone);
        for i, energy in ipairs(energies) do
            energy_msg = energy_msg..string.format("\n%s;%s/%s", energy['user'], energy['cur_energy'], energy['energy_level']);
        end;

        if 'conference-energy' == energy_msg then
            logger.debug('No member energies to dispatch');
        else
            local members = getConferenceMembers(confPhone);
            dispatchSMS(members, energy_msg);
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

        local msg = 'conference-members';
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
          
            msg = msg .. sqlstring.format('\n%s;%s;%s;', user, name, oct_to_hex[flags]);
        end;

        return msg;
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
        local cmd = string.format("conference/api_dispatch_member_list.lua %s", confPhone);
        setTimeoutIfAbsent(id, cmd, 1024);
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
    
    return string.format('%s;%s;%s;%s;', info['name'], info['creator'], info['creator_name'], info['age']);

end;

function formatConferenceFull(info)
    if nil == info then return ''; end;
    return string.format('%s;%s;%s;%s;%s;%s/%s;', 
            info['conference'], info['name'], info['creator'], info['creator_name'], info['age'], info['num_is_in'], info['num_member']
        );
end;
