@echo off

set IMAGE_NAME=ssh-agent-forwarder
set CONTAINER_NAME=ssh-agent-forwarder
set VOLUME_NAME=ssh-agent-forwarder-data
set LOCAL_STATE=~/.ssh-agent-forwarder
set LOCAL_PORT=2244

docker volume inspect %VOLUME_NAME% > nul 2> nul && goto :volume-done
echo "Initial setup of volume %VOLUME_NAME%"
docker volume create %VOLUME_NAME%
:volume-done

docker rm -f %CONTAINER_NAME% > nul
IF EXIST "auth_keys" (
    set AUTH_KEYS="%cd%\auth_keys"
) ELSE (
    set AUTH_KEYS="~/.ssh/id_rsa.pub"
)
echo Using %AUTH_KEYS% as authorization key file

rem  -v %AUTH_KEYS%:/root/.ssh/authorized_keys 

docker run --name %CONTAINER_NAME% ^
  -v %VOLUME_NAME%:/docker-ssh ^
  -d -p %LOCAL_PORT%:22 %IMAGE_NAME% > nul || goto :error
type %AUTH_KEYS% | docker exec -i %CONTAINER_NAME% "/root/ssh-update-keys.sh"

rem set IP=`docker inspect --format '{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostIp ' %CONTAINER_NAME%`
FOR /F "tokens=*" %%g IN ('docker inspect --format "{{(index (index .NetworkSettings.Ports \"22/tcp\") 0).HostIp}}" %CONTAINER_NAME%') do (SET IP=%%g)
IF "%IP%"=="0.0.0.0" SET IP="localhost"
echo Local IP=%IP%
ssh-keyscan -p %LOCAL_PORT% %IP%

ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" ^
  -A -p %LOCAL_PORT% root@%IP% ^
  /root/ssh-forward-agent.sh || goto :error

echo 'Agent forwarding successfully started.'
echo "Use -v %VOLUME_NAME%:/docker-ssh when starting docker containers"

exit /b

:error
exit /b
