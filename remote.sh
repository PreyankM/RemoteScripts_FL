#!/bin/bash

# Define the list of hosts to run the SAR command on
hosts=()

# Define the usernames for each host
usernames=

# Define the remote command to run SAR and collect data
remote_cmd=$(cat << 'END_CMD'
trap "exit" INT
sar -u -r -d -n DEV --iface=eth0 -h 1 > "$USER-sar.txt" &
echo "SAR data collection started on $HOSTNAME."
wait
END_CMD
)

# Start collecting data on all hosts
for ((i=0;i<${#hosts[@]};++i)); do
    host=${hosts[i]}
    username=${usernames[i]}
    ssh "$username@$host" "$remote_cmd" >/dev/null 2>&1 &
done

# Start time of recording
start=$(date +%s)

echo "SAR data collection started on all hosts."

# Wait for user input to stop collecting data
read -p "Press enter to stop collecting SAR data."

color1='\033[1;36m'; # set the color to bold cyan
color2='\033[1;32m'; # set the color to bold green

# Stop collecting data on all hosts
for ((i=0;i<${#hosts[@]};++i)); do
    host=${hosts[i]}
    username=${usernames[i]}
    ssh "$username@$host" "kill -INT \$(pgrep sar)" >/dev/null 2>&1
    echo -e "SAR data collection stopped on ${color1}${host}\033[0m."
done

# Record approximate run time of sar command
elapsed=$(($(date +%s) - start))
echo "";
echo -e "Time Taken : \033[1;32m$(date -d@$elapsed -u +%H\ hours\ %M\ min\ %S\ sec)\033[0m"

# Collect the data files and transfer to trigger machine
for ((i=0;i<${#hosts[@]};++i)); do
    host=${hosts[i]}
    username=${usernames[i]}
   # ls -l
   scp $username@$host:$username-sar.txt user@127.0.0.1:/path/to/storage-directory
   echo "";
    echo -e "SAR data file transferred from ${color1}${host}\033[0m."
    echo "";

    color='\033[1;31m' # set the color to bold red
    echo -e "${color}${username}\033[0m" # print the message in bold red

awk '/^Average:/ {
  if ($2 == "CPU") {
    printf("%s%s%s\n", "\033[1;32m", "CPU", "\033[0m")
    print "%user", "%system"
    getline
    print $3, $5
  }
  if ($2 == "kbmemfree") {
    printf("%s%s%s\n", "\033[1;32m", "Memory", "\033[0m")
    print "kbmemused", "%memused"
    getline
    print $4, $5
  }
  if ($2 == "tps") {
    printf("%s%s%s\n", "\033[1;32m", "Disk", "\033[0m")
    print "rkB/s", "wkB/s"
    getline
    print $3, $4
  }
  if ($2 == "rxpck/s") {
    printf("%s%s%s\n", "\033[1;32m", "Network", "\033[0m")
    print "rxpck/s", "txpck/s"
    getline
    print $2, $3
  }
}' $username-sar.txt | column -t
done
echo "";
echo "All SAR data files collected."
