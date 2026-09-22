*** Settings ***
Library     SSHLibrary
Resource    api.resource

*** Test Cases ***
Back up the module
    ${repo}    ${path} =    Back up the module to the cluster repository    ${module_id}
    Set Global Variable    ${BACKUP_REPO}    ${repo}
    Set Global Variable    ${BACKUP_PATH}    ${path}

Remove the original instance
    # org.nethserver.max-per-node=1: a second instance is refused while the first exists.
    # After the removal wait out logind's user stop delay: on Rocky 9 (systemd 252) a
    # module re-created within seconds gets the same UID back, the user manager for that
    # UID is not started again and the agent of the new instance never comes up.
    Run on node    remove-module --no-preserve ${module_id}
    Sleep    45s

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
    # Asked at the backend of the restored instance, not through Traefik: the stopped
    # original still owns a route for the same host name, so the host header is ambiguous.
    ${route} =    Run task    module/traefik1/get-route    {"instance":"${restored_id}"}
    Should Be Equal    ${route['host']}    netboot.ci.test
    ${code} =    Run on node    curl -sS -o /dev/null -w '\%{http_code}' -u 'ciadmin:Boot#Pass 12' ${route['url']}/
    Should Be Equal As Strings    ${code.strip()}    200
