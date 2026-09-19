*** Settings ***
Library     SSHLibrary
Resource    api.resource

*** Test Cases ***
Install the module
    IF    '${SCENARIO}' == 'update'
        ${output}  ${rc} =    Execute Command    add-module ${UPDATE_FROM} 1    return_rc=True
    ELSE
        ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1    return_rc=True
    END
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${module_id}    ${output.module_id}

Configure the module
    ${ip} =    Run on node    ip -4 route get 1.1.1.1 | sed -n 's/.* src \\([0-9.]*\\).*/\\1/p'
    Set Global Variable    ${NODE_IP}    ${ip.strip()}
    Run task    module/${module_id}/configure-module
    ...    {"host":"netboot.ci.test","lets_encrypt":false,"http2https":true,"admin_user":"ciadmin","admin_password":"Boot#Pass 12","ip_allowlist":[],"pxe_server_ip":"${NODE_IP}","proxy_dhcp":false,"uefi_boot_mode":"standard"}
    ...    decode_json=${FALSE}

The web application and TFTP are up
    Wait Until Keyword Succeeds    60 times    10 seconds    Web login works and TFTP listens

Update to the image under test
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}
    Run on node    api-cli run update-module --data '{"force":true,"module_url":"${IMAGE_URL}","instances":["${module_id}"]}'
    Wait Until Keyword Succeeds    60 times    10 seconds    Web login works and TFTP listens

Configuration reads back
    ${cfg} =    Run task    module/${module_id}/get-configuration    {}
    Should Be Equal    ${cfg['host']}    netboot.ci.test
    Should Be Equal    ${cfg['admin_user']}    ciadmin
    Should Be True    ${cfg['admin_password_set']}
    Should Be Equal    ${cfg['pxe_server_ip']}    ${NODE_IP}

Secrets are kept out of the module environment
    # this module never stored a secret in the environment: the web password is
    # a SHA-512 crypt entry in state/htpasswd (0600)
    ${mode} =    Run on node    runagent -m ${module_id} bash -c 'stat -c \%a "$AGENT_STATE_DIR/htpasswd"'
    Should Be Equal As Strings    ${mode.strip()}    600
    ${leaks} =    Run on node    redis-cli --raw HKEYS module/${module_id}/environment | grep -Eci "PASS|SECRET|TOKEN" || true
    Should Be Equal As Integers    ${leaks.strip()}    0

*** Keywords ***
Web login works and TFTP listens
    ${code} =    Run on node    curl -sSk -o /dev/null -w '\%{http_code}' -H 'Host: netboot.ci.test' https://127.0.0.1/
    Should Be Equal As Strings    ${code.strip()}    401
    ${code} =    Run on node    curl -sSk -o /dev/null -w '\%{http_code}' -u 'ciadmin:Boot#Pass 12' -H 'Host: netboot.ci.test' https://127.0.0.1/
    Should Be Equal As Strings    ${code.strip()}    200
    ${n} =    Run on node    ss -lun | grep -c ':69 ' || true
    Should Not Be Equal As Integers    ${n.strip()}    0
