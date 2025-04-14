#!/bin/bash

##############################################
# Take 1 parameter:
#   prompt: first static text before spinner
# Get the pid of the latest background command
# Print the first static text (first argument)
# Print the next dynamic text (spin animation)
# Stop once last process is completed
##############################################

load_spin() {
    pid=$2 # PID of the background process
    spin=('-' '\' '|' '/') # Spinner animation frames
    echo -n "$1 ${spin[0]}"
    while kill -0 $pid 2>/dev/null; do
        for i in "${spin[@]}"; do
            echo -ne "\b$i"
            sleep 0.1
        done
    done

    wait $pid
    exit_status=$?

    if [ $exit_status -eq 0 ]; then
        echo -e "\b✓ Done!"
    else
        echo -e "\b✗ Failed!"
    fi

    return $exit_status
}

##############################################
# Take 3 parameters:
#   variable: name to save return value to
#   command: command to execute and get value
#   prompt: line that's printed before spinner
# Run command and play spinner till complete
##############################################

async_task() {
    outfile=$(mktemp)
    bash -c "$2" > "$outfile" 2>&1 &
    pid=$!
    load_spin "$3" "$pid"
    exit_status=$?

    if [ $exit_status -ne 0 ]; then
        echo "----- Error Output -----"
        cat "$outfile"
        echo "------------------------"
        exit $exit_status
    elif [ ! -z "$1" ]; then
        eval "$1=\"$(<"$outfile")\""
    fi
    rm "$outfile"
}

##############################################
# Take 1 parameter:
#   type: category of the log message
# Print line of timedate and messagge type
# Default: [INFO]
##############################################

get_log_format() {
    if [ "$1" == "" ]; then 
        type="INFO"
    else
        type=$1
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$type]"
}

##############################################
# Take 1 parameter:
#   ec2_id: the id of the EC2 instance
#   time: wait interval for each check
# Check for the status of the EC2 instance
# Break when status is running
##############################################

wait_ec2_init() {
    if [[ "$1" == "" ]]; then
        sleep_interval=10
    else
        sleep_interval=$1
    fi
    status_checks=$(aws ec2 describe-instance-status --instance-ids $2 --query "[InstanceStatuses[0].InstanceStatus.Status, InstanceStatuses[0].SystemStatus.Status]" --output text)
    instance_status=$(echo "$status_checks" | awk '{print $1}')
    system_status=$(echo "$status_checks" | awk '{print $2}')
    while [[ ! ("$instance_status" == "ok" && "$system_status" == "ok") ]]; do
        sleep $sleep_interval
        status_checks=$(aws ec2 describe-instance-status --instance-ids $2 --query "[InstanceStatuses[0].InstanceStatus.Status, InstanceStatuses[0].SystemStatus.Status]" --output text)
        instance_status=$(echo "$status_checks" | awk '{print $1}')
        system_status=$(echo "$status_checks" | awk '{print $2}')
    done
}

##############################################
#                    TEST                    #
##############################################

test() {
    var="var1"
    command="sleep 3; echo 1"
    prompt="$(get_log_format) Doing very important thing"
    async_task "$var" "$command" "$prompt"
}
