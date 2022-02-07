#!/bin/bash
#Exits if variables are not set or command fails.
set -eu pipefail
#Set variables to use
NODE_REPORT="Nodes_Port_Status_`date '+%H%M-%m%d%Y'`.txt"
#Convert string to array in case of multiple values to ignore
WHITELISTED_PORTS=($IGNORE_LIST)
#Functions needed
#Convert array to csv string
joinByChar() {
    local IFS="$1"
    shift
    echo "$*"
}
#Beautify report output with Header and Table like format.
addHeaders() {
    sed  -i '1i NODE OPEN_PORTS' $1
    #Using sponge so it doesnt delete the file when it rewrites it.
    column -s " " -t $1 |sponge $1
}
#Get kubernetes node names and internal ips an save to temporary file. We need a serviceaccount attached to pod for this command to work. View Readme
kubectl get nodes -o custom-columns=NODE:.metadata.name,'IP:.status.addresses[?(@.type=="InternalIP")].address' --no-headers > nodes.txt
#Parse the nodes and ips from temporary file, checks if they are open with nmap and if it's in the ignore list remove it from array.
while read field1 field2; do
    #echo "Checking for $field1 with IP $field2"
    open_ports=(`nmap -sT $field2 | grep open | awk -F/ '{print$1}'`)
    for port in "${WHITELISTED_PORTS[@]}"; do
        for i in "${!open_ports[@]}"; do
            if [[ ${open_ports[i]} = $port ]]; then
                unset 'open_ports[i]'
            fi
        done
    done
    #Loop through array to send open ports of each node to pushgateway
    for port in "${open_ports[@]}"; do
      echo $field1 $port
      #echo $field1 $open_ports | curl --data-binary @- http://172.20.103.195:9091/metrics/job/node-port-status/instance/172.20.103.195
    done
    #Convert array to csv string for easy parse
    open_ports=`joinByChar , ${open_ports[@]}`
    #Write results in result file.
    echo $field1: [$open_ports] >> $NODE_REPORT
done < nodes.txt
addHeaders $NODE_REPORT
#Upload to s3 bucket from bucket defined in YAML file. !!!!We need to have the credentials for aws so we can upload to S3!!!
aws s3 cp $NODE_REPORT s3://$AWS_BUCKET > /dev/null 2>&1