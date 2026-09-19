*** Settings ***
Library     SSHLibrary
Resource    api.resource

*** Test Cases ***
Back up the module
    ${repo}    ${path} =    Back up the module to the cluster repository    ${module_id}
    Set Global Variable    ${BACKUP_REPO}    ${repo}
    Set Global Variable    ${BACKUP_PATH}    ${path}

Remove the original instance
    # TFTP and proxyDHCP listen on the node network: one instance per node
    Run on node    remove-module --no-preserve ${module_id}

Restore into a new instance
    ${rid} =    Restore the module from the cluster repository    ${BACKUP_REPO}    ${BACKUP_PATH}
    Set Global Variable    ${restored_id}    ${rid}
    Set Global Variable    ${module_id}    ${rid}

The restored instance has settings and the web password
    ${cfg} =    Run task    module/${restored_id}/get-configuration    {}
    Should Be Equal    ${cfg['host']}    netboot.ci.test
    Should Be Equal    ${cfg['admin_user']}    ciadmin
    Should Be True    ${cfg['admin_password_set']}
    Should Be Equal    ${cfg['pxe_server_ip']}    ${NODE_IP}
    Wait Until Keyword Succeeds    60 times    10 seconds    Restored web login works

*** Keywords ***
Restored web login works
    ${code} =    Run on node    curl -sSk -o /dev/null -w '\%{http_code}' -u 'ciadmin:Boot#Pass 12' -H 'Host: netboot.ci.test' https://127.0.0.1/
    Should Be Equal As Strings    ${code.strip()}    200
