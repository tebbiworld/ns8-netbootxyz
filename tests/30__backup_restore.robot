*** Settings ***
Library     SSHLibrary
Resource    api.resource

*** Test Cases ***
Back up the module
    ${repo}    ${path} =    Back up the module to the cluster repository    ${module_id}
    Set Global Variable    ${BACKUP_REPO}    ${repo}
    Set Global Variable    ${BACKUP_PATH}    ${path}

Stop the original instance
    # TFTP and proxyDHCP listen on the node network: one instance per node
    # Stopped, not removed: on Rocky 9 (systemd 252) a module removed and re-created
    # within seconds gets the same UID back, the user manager for that UID is not
    # started again and the agent of the new instance never comes up. Only the units shipped by
    # the module are stopped: its agent (agent.service) must keep running, or the
    # instance can no longer be removed.
    Run on node    runagent -m ${module_id} bash -c 'cd ~/.config/systemd/user && ls *.service *.timer 2>/dev/null | xargs -r systemctl --user disable --now'

Restore into a new instance
    ${rid} =    Restore the module from the cluster repository    ${BACKUP_REPO}    ${BACKUP_PATH}
    Set Global Variable    ${restored_id}    ${rid}
    Should Not Be Equal    ${restored_id}    ${module_id}

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
