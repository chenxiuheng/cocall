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

local logger = getLogger('conference');

---------------   Conference DAO ---------------------------------------------
function getConferenceMembers(confPhone, user, except)
    local sql;

    sql = string.format(
        " SELECT DISTINCT "..
        " mem.c_phone_no  as user, "..
        " mem.c_name      as name, "..
        " mem.n_is_in as is_in, "..
        " mem.c_member_type as type, "..
        " mem.n_member_id as member_id, "..
        " mem.n_can_speak as can_speak, "..
        " r.realm as realm, "..
        " mem.n_is_modirator as is_moderator "..
        " FROM "..
        " t_conference_member AS mem "..
        " LEFT JOIN registrations AS r ON mem.c_phone_no = r.reg_user "..
        " where mem.c_conference_phone_no = '%s' ",
        confPhone
    );

    if 'non_moderator' == user then 
        sql = sql .. "  and n_is_modirator <> 1";
    elseif 'moderator' == user then
        sql = sql .. "  and n_is_modirator = 1";
    elseif 'all' ~= user and nil ~= user then
        sql = sql .. string.format(" AND mem.c_phone_no='%s'", user);
    end;

    if 'non_moderator' == except then 
        sql = sql .. "  and n_is_modirator = 1";
    elseif 'moderator' == except then
        sql = sql .. "  and n_is_modirator <> 1";
    elseif nil ~= user then
        sql = sql .. string.format(" AND mem.c_phone_no<>'%s'", except);
    end;

    local memberIndex = 1;    
    local members = {};
    executeQuery(sql, function(row)
        if not isTrue(row['realm']) then
            row['is_in'] = '2';
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
        sql = sql .. " set " .. field .. string.format("='%s'", value);
    else    
        sql = sql .. " set " .. field .. string.format("=%s", value);
    end;

    sql = sql .. string.format(" where c_conference_phone_no = '%s' ", confPhone);

    if 'non_moderator' == user then
        sql = sql .. "  and n_is_modirator <> 1 ";
    elseif nil ~= user then
        sql = sql .. string.format("  and c_phone_no = '%s' ", user);
    end;

    executeUpdate(sql);
end;

function setConferenceModerator(confPhone, user)
    local sql;
    sql = string.format(
            "update t_conference set c_modirator_phone_no='%s' where c_phone_no='%s' ",
            user, confPhone
        );
    executeUpdate(sql);
    
    sql = string.format(
            "update t_conference_member set n_is_modirator = (case when c_phone_no = '%s' then 1 else 2 end)  "..
            " where c_conference_phone_no='%s'",
            user, confPhone
        );
    executeUpdate(sql);
end;

function setConferenceMemberIn (confPhone, user, memberId)
    if nil == user then return ;end;

    local sql;
    sql = string.format(
            "update t_conference_member set n_is_in=1, n_member_id=%s "..
            " where n_is_in<>1 and c_conference_phone_no = '%s' and c_phone_no='%s' ",
            memberId, confPhone, user
        ); 

    executeUpdate(sql);
end;

function setConferenceMemberOut(confPhone, user, memberId)
    local sql;

    -- 1, update DB state, the member must be last used.
    --     if the member id in DB is not eq memberId arg, do nothing
    sql = string.format(
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
    local sql = string.format(
            'insert into t_conference  '..
            ' (c_phone_no, c_modirator_phone_no, c_name, c_creator, c_creator_name, d_created, d_plan, n_valid, c_profile,  n_is_running)'..
            "values ('%s', '%s', '%s', '%s', '%s', now(), now(), 1, 'default', 2)",
            phoneNo, creator, name, creator, creatorName
        );
    executeUpdate(sql);

    -- 3, return conf phone no
    return phoneNo;
end;

function setConferenceIsRunning(confPhone, n_is_running)
    local sql;
    sql = string.format("update t_conference set n_is_running =%s where c_phone_no='%s'",
            n_is_running,
            confPhone
        );
    executeUpdate(sql);
end;

function getConferenceInfo(confPhone)
    local sql = string.format(
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

    local sql = string.format(
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
            ' (select count(*) from t_conference_member where c_conference_phone_no=conf.c_phone_no and n_is_in = 1) as num_online'..
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
    local info = nil;
    local service = {};

    function getInfo()
        if nil == info then info = getConferenceInfo(confPhone); end;
        return info;
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
    end;

    service.addMember=function(member)


        local uuid = confPhone..'.'..member['user'];
        local user = member['user'];
        local name = member['name'];

        -- check it existed
        local sql;
        local existed = false;
        sql = string.format(
                "select count(*) num from t_conference_member where c_conference_phone_no = '%s' and c_phone_no = '%s'",
                confPhone, user
            );
        executeQuery(sql, function(row)
            if row['num'] ~= '0' then existed = true end;
        end);

        if existed then return true; end; -- existed, do nothing
        

        local info = getInfo();
        if nil == info then return false; end; -- NO conference found
        if not isTrue(info['valid']) then 
            logger.warn("can't add-member in invalid conference[", confPhone, ']');
            return false; 
        end; -- not valid

        -- insert into DB if not existed
        local isModerator =  2;
        if member['user'] == info['moderator'] then isModerator = 1 end;

        sql = string.format(
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
            freeswitch.API():execute('conference', confPhone..' kick '.. member_id);
            logger.info('kick ', member['user'], 'from conference[', confPhone, '] member-id=', member_id);
            sendSMS(confPhone, member['user'], 'conference-kicked', 'you are kick by ' .. operator);
        end;

        -- delete from db
        sql = string.format(
                " delete from t_conference_member "..
                " where c_conference_phone_no = '%s' "..
                "   AND c_phone_no = '%s'",
                 confPhone, user
            );
        executeUpdate(sql);

    end;

    service.destroy = function ()
        -- set conference invalid
        local sql;
        sql = string.format(
               "update t_conference set n_valid = 2 where c_phone_no='%s'",
                confPhone
            );
        executeUpdate(sql);

        -- kick from swtich
        local is_in;
        local memberId;
        local to;
        local members = getConferenceMembers(confPhone);
        for i, member in ipairs(members) do
            is_in = member['is_in'];
            memberId = member['member_id'];
            to = member['user']..'@'..member['realm'];
            freeswitch.API():execute('conference', confPhone ..' kick '.. memberId);

            if isTrue(is_in) then
                send(confPhone, to, 'destroy');
            end;
        end;

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
                    -- ignore moderator
            else
                if isTrue(is_in) then
                    freeswitch.API():execute('conference', confPhone ..' mute '.. memberId);
                end;
            end;
        end;
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
                    -- ignore moderator
            else
                if isTrue(is_in) then
                    freeswitch.API():execute('conference', confPhone ..' unmute '.. memberId);
                end;
            end;
        end;
    end;

    service.setModerator = function(user)
        local sql;
        
        -- update DB
        sql = string.format(
                "update t_conference set c_modirator_phone_no='%s' where c_phone_no='%s' ",
                user, confPhone
            );
        executeUpdate(sql);

        sql = string.format(
                "update t_conference_member set n_is_modirator = (case when c_phone_no = '%s' then 1 else 2 end) where c_conference_phone_no='%s' ",
                user, confPhone
            );
        executeUpdate(sql);


        -- change switch
        local members = service.getMembers('moderator');
        for i, member in ipairs(members) do
            local is_in = member['is_in'];
            local member_id = member['member_id'];

            if  isTrue(is_in) then
                freeswitch.API():execute('conference', service.getPhoneNo()..' vid-floor '..member_id ..' force');
            end;
        end;
    end;

    service.notifyAll = function(filter) 
        local sql;
        local members;
        local msg = ''; -- msg to dispatch to members

        -- 2, get member's states
        members = getConferenceMembers(confPhone);
        
        
        -- 3, build msg
        for i, member in ipairs(members) do
            local user = member['user'];
            local name = member['name'];
            local realm = member['realm'];
            local is_in = member['is_in'];
            local can_speak = member['can_speak'];
            local is_moderator = member['is_moderator'];
           
            local online = 'online';
            if isFalse(realm) then online = 'offline' end;

            local isInConference = 'out';
            if isTrue(is_in) then isInConference = 'in' end;

            local mute = 'mute';
            if isTrue(can_speak) then mute = 'unmute'; end;

            local member = 'member';
            if isTrue(is_moderator) then member = 'moderator';end;

            msg = msg .. string.format('%s;%s;%s;%s;%s;%s;\n', user, name, online, isInConference, mute, member);
     
        end;

        logger.debug("conference-members", msg);

        -- 4, dispatch msg to members who is in conference
        for i, member in ipairs(members) do
            local user = member['user'];
            local name = member['name'];
            local realm = member['realm'];
            local is_in = member['is_in'];


            if isTrue(realm) and (nil == filter or user == filter) then -- and isTrue(is_in), maybe the state is reliable 
                local to = user ..'@'..realm;
                sendSMS(confPhone, to, "conference-members", msg);
            end;       
        end;  
    end;

    service.toSimpleString = function() 
        return formatConference(getInfo());
    end;

    service.sayTo = function(dstUser, from_user, arg0, arg1, arg2, arg3, arg4)
        local members = service.getMembers(dstUsers, from_user); -- except myself
        local sentIt;
        for i, member in ipairs(members) do
            local is_in = member['is_in'];
            local to = member['user']..'@'.. member['realm'];

            sentIt = sendSMS(confPhone, to, arg0, arg1, arg2, arg3, arg4) or sentIt;
        end;

        return sentIt;
    end;

    return service;
end;

function formatConference(info)
    if nil == info then return ''; end;
    
    return string.format('%s;%s;%s;%s;', info['name'], info['creator'], info['creator_name'], info['age']);

end;

function formatConferenceFull(info)
    if nil == info then return ''; end;
    return string.format('%s;%s;%s;%s;%s;', info['conference'], info['name'], info['creator'], info['creator_name'], info['age']);
end;
