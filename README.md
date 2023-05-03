# RemoteScripts_FL
Using SSH to enable SAR command on remote devices and collecting output(in txt files). The files are stored in the path specified.
This script also clears cache and swap space remotely. It also clears process that occupy a specific port number(as specified).
This is a part of a project from DaSH Lab(BITS Goa).

- batch.sh  
Usage : `./batch.sh`
Description :
    1. Activate clear_cache_all_pis.sh (Asks for raspi password) - line 3
    
    ```bash
    expect /path/to/script/clear_cache_all_pis.sh
    ```
    
    2. Activate clear_cache_on_agg.sh on the aggregator (Asks for sudo password) - line 9
    
    ```bash
    sudo bash /path/to/script/clear_cache_on_agg.sh 5000
    ```
    
    3. Waits for Enter press before starting SAR commands on all mentioned hosts and ips - line 39
    
    ```bash
    # Wait for user input to start collecting data
    read -p "Press enter to start collecting SAR data."
    ```
    
    4. Starts SAR on all devices including local device - line 42
    
    ```bash
    # Start collecting data on all hosts
    for ((i=0;i<${#hosts[@]};++i)); do
        host=${hosts[i]}
        username=${usernames[i]}
        if [ "$username" = "user" ]; then
        # do something
          ssh "$username@$host" "$remote_cmd2" >/dev/null 2>&1 &
        else
        # do something else
          ssh "$username@$host" "$remote_cmd" >/dev/null 2>&1 &
    fi
    done
    ```
    
    5. Waits for Enter press before stopping SAR commands on all mentioned hosts and ips - line 60
    
    ```bash
    # Wait for user input to stop collecting data
    read -p "Press enter to stop collecting SAR data."
    ```
    
    6. Stops SAR on all devices including local device - line 66
    
    ```bash
    # Stop collecting data on all hosts
    for ((i=0;i<${#hosts[@]};++i)); do
        host=${hosts[i]}
        username=${usernames[i]}
        ssh "$username@$host" "kill -INT \$(pgrep sar)" >/dev/null 2>&1
        echo -e "SAR data collection stopped on ${color1}${host}\033[0m."
    done
    ```
    
    7. Collects data from all remote devices and stores in the the given directory - line 79 
    
    ```bash
    for ((i=0;i<${#hosts[@]};++i)); do
        host=${hosts[i]}
        username=${usernames[i]}
       # ls -l
       scp $username@$host:$username-sar.txt user@127.0.0.1:/path/to/directory
    ```
    
    8. Pretty prints required avg parameters from the SAR files - line 91 
    
    ```bash
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
    ```
    

- clear_cache_all_pis.sh
Usage : `except clear_cache_all_pis.sh`
Description : This is not a shell script rather an expect script which allows to spawn a remote shell and lets us pass password for sudo commands
    1. Takes password once and stores it to pass as argument whenever the spawned shell asks for password - line 13
    
    ```bash
    puts -nonewline "Enter password: "
    flush stdout
    stty -echo
    expect_user -re "(.*)\n"
    set password $expect_out(1,string)
    stty echo
    puts ""
    ```
    
    2. Runs the clear_cache_port on all raspberry pis using a spawned ssh shell - line 21
    
    ```bash
    foreach host $hosts username $usernames port $ports {
      spawn ssh $username@$host "./path/to/script/clear_cache_on_pi.sh ${port}"
      expect {
        "*password*" {
          send -- "$password\r"
          exp_continue
        }
        eof
      }
      puts "Clear cache executed on $host."
    }
    ```
    
- clear_cache_on_agg.sh
Usage : `./clear_cache_on_agg.sh <PORT Number to be cleared>`
Description : Clears cache, swap memory and frees up the port number.
    1. Frees up port number by killing the process running on it if any.
    
    ```bash
    sudo kill -9 $(sudo lsof -t -i :$1)
    ```
    
    2. Clears all cache(memory buffers) 
    
    ```bash
    sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
    ```
    
    3. Clears swap space 
    
    ```bash
    sudo swapoff -a && sudo swapon -a
    ```
    

NOTE : For clearing swap space if the above code doesn’t work use the one used in the script below

- clear_cache_on_pi.sh
Usage : `./clear_cache_on_pi.sh <PORT Number to be cleared>`
Description : Clears cache, swap memory and frees up the port number.
    1. Frees up port number by killing the process running on it if any.
    
    ```bash
    sudo kill -9 $(sudo lsof -t -i :$1)
    ```
    
    2. Clears all cache(memory buffers) 
    
    ```bash
    sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
    ```
    
    3. Clears swap space 
    
    ```bash
    sudo swapoff -a && sudo swapon /var/swap
    ```
    

NOTE : For clearing swap space if the above code doesn’t work use the one used in the script above or try and locate the swap space location and use that instead of /var/swap

NOTE : If the script shows usage of kill that means that it did not receive any pid to kill from the `lsof` command, which means that the port was already free. It is not an error.
