#!/bin/bash
#Author - Preyank Mota

#Killing process at the given ports
sudo kill -9 $(sudo lsof -t -i :$1)

#Clearing cache
sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"

#Clear swap
sudo swapoff -a && sudo swapon /var/swap