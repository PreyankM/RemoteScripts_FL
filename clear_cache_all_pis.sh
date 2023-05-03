#!/usr/bin/expect
#Author - Preyank Mota

# Define the list of hosts to run the SAR command on
set hosts [list "x.x.x.x" "x.x.x.x" "x.x.x.x" "x.x.x.x"]

# Define the usernames for each host
set usernames [list "user1" "user2" "user3" "user4"]

# Define ports
set ports [list "8085" "8086" "8087" "8088"]

# Prompt the user for the password
puts -nonewline "Enter password: "
flush stdout
stty -echo
expect_user -re "(.*)\n"
set password $expect_out(1,string)
stty echo
puts ""

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
