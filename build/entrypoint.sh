#!/bin/bash
# generate kubeedge config
/kubeedge/generate.sh

mount --make-rshared /
source /opt/bash-utils/logger.sh

function wait_for_process () {
    local max_time_wait=30
    local process_name="$1"
    local waited_sec=0
    while ! pgrep "$process_name" >/dev/null && ((waited_sec < max_time_wait)); do
        INFO "Process $process_name is not running yet. Retrying in 1 seconds"
        INFO "Waited $waited_sec seconds of $max_time_wait seconds"
        sleep 1
        ((waited_sec=waited_sec+1))
        if ((waited_sec >= max_time_wait)); then
            return 1
        fi
    done
    return 0
}

INFO "Starting supervisor"
/usr/bin/supervisord -n >> /dev/null 2>&1 &

INFO "Waiting for processes to be running"
processes=(dockerd)

for process in "${processes[@]}"; do
    wait_for_process "$process"
    if [ $? -ne 0 ]; then
        ERROR "$process is not running after max time"
        exit 1
    else
        INFO "$process is running"
    fi
done

# Test if cloudcore is up and running before trying to register
echo "Waiting until all cloudcore ports are reachable"
while :
do
    sleep 1
    echo trying port 10000
    port10000=$(echo | openssl s_client -verify_return_error -connect ${CLOUDCORE_ADDRESS}:10000 2>/dev/null | awk -F\: '$1 ~ "Verify return code"{print $2}' | awk -F " " '{print $1}')
    echo trying port 10002
    port10002=$(echo | openssl s_client -verify_return_error -connect ${CLOUDCORE_ADDRESS}:10002 2>/dev/null | awk -F\: '$1 ~ "Verify return code"{print $2}' | awk -F " " '{print $1}')
    echo trying port 10003
    port10003=$(echo | openssl s_client -verify_return_error -connect ${CLOUDCORE_ADDRESS}:10003 2>/dev/null | awk -F\: '$1 ~ "Verify return code"{print $2}' | awk -F " " '{print $1}')
    echo trying port 10004
    port10004=$(echo | openssl s_client -verify_return_error -connect ${CLOUDCORE_ADDRESS}:10004 2>/dev/null | awk -F\: '$1 ~ "Verify return code"{print $2}' | awk -F " " '{print $1}')
    i=0
    [[ -z "$port10000" ]] && continue && echo found; i=$((i+1))
    [[ -z "$port10002" ]] && continue && echo found; i=$((i+1))
    [[ -z "$port10003" ]] && continue && echo found; i=$((i+1))
    [[ -z "$port10004" ]] && continue && echo found; i=$((i+1))

    echo $i
    if [ "$i" -eq 4 ]; then
        echo All cloudcore ports reachable.
        break
    fi
done

# Start the first process
echo Starting edgecore
mkdir -p /var/log/kubeedge
/usr/local/bin/edgecore

status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start my_second_process: $status"
    exit $status
fi

# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with an error
# if it detects that either of the processes has exited.
# Otherwise it loops forever, waking up every 60 seconds

while sleep 60; do
    ps aux |grep my_first_process |grep -q -v grep
    PROCESS_1_STATUS=$?
    #  ps aux |grep my_second_process |grep -q -v grep
    #  PROCESS_2_STATUS=$?
    # If the greps above find anything, they exit with 0 status
    # If they are not both 0, then something is wrong
    #  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 ]; then
    if [ $PROCESS_1_STATUS -ne 0 ]; then
        echo "processes has already exited."
        exit 1
    fi
done
