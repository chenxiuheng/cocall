local api = freeswitch.API();
local scripts_base_dir = api:execute("global_getvar", "base_dir")..'/scripts';
if nil == string.find(package.path, scripts_base_dir) then
    package.path = package.path..';'..
                scripts_base_dir..'/?.lua'..';';
end;
require('libs.db');
require('libs.commons');
require('user.userService');


freeswitch.consoleLog("debug", "provided params:\n" .. params:serialize() .."\n")

local key = params:getHeader('key');
local user = params:getHeader('user');
local name = params:getHeader('name');
local password = params:getHeader('passwd');
local domain = params:getHeader('domain');
local ip = params:getHeader('ip');
local port = params:getHeader('client_port');

assert (domain and user,
  "This example script only supports generating directory xml for a single user !\n")


if domain ~= nil and key~=nil and user~=nil then
    password = saveOrUpdateUser(user, user, name, password);

    XML_STRING =
    [[<?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <document type="freeswitch/xml">
      <section name="directory">
        <domain name="]]..domain..[[">
          <params>
        <param name="dial-string"
        value="{presence_id=${dialed_user}@${dialed_domain}}${sofia_contact(${dialed_user}@${dialed_domain})}"/>
          </params>
          <groups>
        <group name="default">
          <users>
            <user id="]] ..user..[[">
              <params>
            <param name="password" value="]]..password..[["/>
            <param name="vm-password" value="]]..password..[["/>
              </params>
              <variables>
            <variable name="toll_allow" value="domestic,international,local"/>
            <variable name="accountcode" value="]] ..user..[["/>
            <variable name="user_context" value="default"/>
            <variable name="directory-visible" value="true"/>
            <variable name="directory-exten-visible" value="true"/>
            <variable name="limit_max" value="15"/>
            <variable name="effective_caller_id_name" value="Extension ]] ..user..[["/>
            <variable name="effective_caller_id_number" value="]] ..user..[["/>
            <variable name="outbound_caller_id_name" value="Cocall-Video-Conference-Admin"/>
            <variable name="outbound_caller_id_number" value="00000000"/>
            <variable name="callgroup" value="techsupport"/>
              </variables>
            </user>
          </users>
        </group>
          </groups>
        </domain>
      </section>
    </document>]]
else
    XML_STRING =
    [[<?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <document type="freeswitch/xml">
      <section name="directory">
      </section>
    </document>]]
end

