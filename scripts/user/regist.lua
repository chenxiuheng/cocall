local api = freeswitch.API();
require('libs.db');
require('libs.commons');
require('user.userService');


--[[ event = 
    Event-Name: REQUEST_PARAMS
    Core-UUID: c6894680-0390-11e5-aea5-c34894ddf95a
    FreeSWITCH-Hostname: localhost.localdomain
    FreeSWITCH-Switchname: localhost.localdomain
    FreeSWITCH-IPv4: 114.255.140.107
    FreeSWITCH-IPv6: %3A%3A1
    Event-Date-Local: 2015-06-02%2021%3A17%3A17
    Event-Date-GMT: Tue,%2002%20Jun%202015%2013%3A17%3A17%20GMT
    Event-Date-Timestamp: 1433251037879273
    Event-Calling-File: sofia_reg.c
    Event-Calling-Function: sofia_reg_parse_auth
    Event-Calling-Line-Number: 2741
    Event-Sequence: 236398
    action: sip_auth
    sip_profile: internal
    sip_user_agent: Linphone/3.8.0%20(belle-sip/1.4.0)
    sip_auth_username: 1018
    sip_auth_realm: 114.255.140.107
    sip_auth_nonce: b15b89be-0929-11e5-aec2-c34894ddf95a
    sip_auth_uri: sip%3A114.255.140.107%3A9060
    sip_contact_user: 1018
    sip_contact_host: 114.255.140.98
    sip_to_user: 1018
    sip_to_host: 114.255.140.107
    sip_via_protocol: udp
    sip_from_user: 1018
    sip_from_host: 114.255.140.107
    sip_call_id: 9S-owrxnqj
    sip_request_host: 114.255.140.107
    sip_request_port: 9060
    sip_auth_qop: auth
    sip_auth_cnonce: 055542fd
    sip_auth_nc: 00000001
    sip_auth_response: 5d915e919473a834928ddfd67b040677
    sip_auth_method: REGISTER
    client_port: 54508
    key: id
    user: 1018
    domain: 114.255.140.107
    ip: 114.255.140.98
]]


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

