#!/bin/bash

#
# Conceptualized by Jerry Rose. Code written by Simon Gagnon
#


# SHOW introductory message
echo " "
echo "--------------------------------------------------------------------------"
echo "|========================================================================|"
echo "|========================================================================|"
echo "|=====							            =====|"
echo "|=====   Welcome to the UDP NMAP Optimization Tool Extraordinaire   =====|"
echo "|=====				v1.0			            =====|"
echo "|========================================================================|"
echo "|========================================================================|"
echo "--------------------------------------------------------------------------"
printf "\n\nThis script is intended to run a light UDP scan slightly faster than a typical NMAP command. The script will run three phases of NMAP commands:\n\nPHASE 1: A 'host-discovery' scan of your target(s)\nPHASE 2: Port enumeration of targets found in Phase 1\nPHASE 3: Service and OS fingerprinting of ports found in PHASE 2\n\n"

# GET user's preferred directory for all saved output
bold=$(tput bold)
normal=$(tput sgr0)
dirLoop=0
while [ $dirLoop -eq 0 ]
do 
	printf "Let's begin! We are going to save your output to a grep-able file. You are currently in $PWD.\n\n"
	read -p "Do you want to change the directory (y/n): " firstChoice
	if [[ "${firstChoice,,}" == "n" ]] || [[ "${firstChoice,,}" == "no" ]]
	then
		preferredDir=$PWD
		dirLoop=1
	elif [[ "${firstChoice,,}" == "y" ]] || [[ "${firstChoice,,}" == "yes" ]]
	then
		echo ""
		read -p "What directory would you like to save your output to: " preferredDir
		if [ ! -d $preferredDir ]
		then
			printf "That directory does not exist. Please try again.\n\n"
		else
			dirLoop=1
		fi
	else
		printf "\nYour input was invalid. Please type either 'y' for yes or 'n' for no\n\n"
	fi
done


printf "\nGreat! Your output will be saved to: ${bold}$preferredDir${normal}. Now, let's select your target(s).\n\n"

# CREATE directories for saved output
theDate=$(date +"%b %d %Y %H%M%S") 
mkdir -p "$preferredDir/nmap scans/nmap scan from $theDate"
cd "$preferredDir/nmap scans/nmap scan from $theDate"


# GET target(s) that will be scanned by NMAP for host discovery
read -p "Select your target(s): " usersTargets
printf "\nStarting PHASE 1: Host Discovery\n================================\n"
sleep 3
nmap -n -sU -T4 -r -p 111,135 --max-retries 0 --version-intensity 0 $usersTargets -oG availableHosts.txt
nmap -sn $usersTargets -oG availableHosts2.txt

# CREATE "All Hosts.txt" file and append all open host addresses found in file
grep Up availableHosts.txt | cut -d " " -f 2 > hostsDiscovered.txt
grep Up availableHosts2.txt | cut -d " " -f 2 >> hostsDiscovered.txt
cat hostsDiscovered.txt | sort -t . -g -k1,1 -k2,2 -k3,3 -k4,4 | uniq > "All Hosts.txt"
rm availableHosts.txt availableHosts2.txt hostsDiscovered.txt

# GET any IP exclusions from user
printf "\n\nPHASE 1 complete.\n-----------------\n\nBefore beginning PHASE 2, would you like to exclude your own IP address from the target list (if applicable)?\n\n"
excludeLoop=0
while [ $excludeLoop = 0 ]
do 
	read -p "Type in your IP address or hit <ENTER> to skip: " excludeIP

	if [[ $excludeIP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
	then
		myExclusion="--exclude $excludeIP"
		echo "$excludeIP"
		excludeLoop=1
	elif [[ $excludeIP = "" ]]
	then
		echo "$excludeIP"
		myExclusion=""
		excludeLoop=1
	else
		printf "Your IP address was not printed in the proper format. Please use the following SYNTAX:\nEXAMPLE 1: 192.168.1.1\nEXAMPLE 2: 192,.168.1.1,192.168.1.8\n\n"
	fi 
done

# START PHASE 2 of NMAP scanning and create "Open Ports.txt" file with all open ports found from scan
printf "\nBeginning PHASE 2: UDP Port Enumeration of Available Hosts\n==========================================================\n"
sleep 3
printf "This can take a while. You may want to go grab some coffee... We'll let you know when this phase has finished :)"
nmap -n -sU -T4 -r -p- --max-retries 0 --version-intensity 0 -iL "All Hosts.txt" $excludeIP > "Open Ports.txt"

cat "Open Ports.txt" | grep "/udp" | cut -f 1 -d " " | cut -f 1 -d "/"| sort -h | uniq > "Open Ports.txt"

printf "\n\nPHASE 2 complete.\n-----------------"

# START PHASE 3 of NMAP scanning and create Full-Report.txt with final output from the scan
printf "\n\nBeginning PHASE 3: Fingerprinting Services and OS Being Used\n============================================================\n\n"
sleep 3

nmap -n -sUVC -r -A -p $(tr '\n' , < "Open Ports.txt") --max-retries 0 version-intensity 0 -iL "All Hosts.txt" -oN "Full Report.txt"

printf "\n\nPHASE 3 complete.\n-----------------"
printf "\n\n\nThese were the available hosts that were discovered from an NMAP scan of target(s) $usersTargets on $theDate" >> "All Hosts.txt"
printf "\n\n\nThese were the open ports found from an NMAP scan of target(s) $usersTargets on $theDate" >> "Open Ports.txt"

# END
printf "\n\nThree files have been created for your convenience in ${bold}$preferredDir${normal}:\n\n${bold}All Hosts.txt${normal} - a list of all available hosts found from PHASE 1\n${bold}Open Ports.txt${normal} - a list of all open ports from PHASE 2\n${bold}Full Report.txt${normal} - the full output of the nmap scan from PHASE 3.\n\n"
read -p "The process is complete. Press <ENTER> to exit script"
