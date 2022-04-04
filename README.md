# UDP-NOTE

Created by Simon Gagnon and Jerry Rose

This script performs a light UDP scan of all specified hosts. Although the speed of the scanning is dependent on the amount of targets being scanned, this script makes nmap slightly faster and more efficient when attempting to discover and fingerprint open UDP ports.

This is done by completing the scan in three phases:

PHASE 1: Host Discovery
-----------------------

Two commands are used for host discovery:
nmap -n -sU -T4 -r -p 111,135 --max-retries 0 --version-intensity 0 IPAddress(es) 

nmap -sn IPAddress(es) 



PHASE 2: Port Enumeration
--------------------------

nmap -n -sU -T4 -r -p- --max-retries 0 --version-intensity 0 IPAddressesFromPhase1



PHASE 3: Service and OS fingerprinting
---------------------------------------

nmap -n -sUVC -r -A -p PortsFromPhase2 --max-retries 0 version-intensity 0 IPAddressesFromPhase1
