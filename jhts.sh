#!/bin/bash

#  jhts.sh
#
#  Copyright 2017 Jack <jackrendor@gmail.com>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#

VERSION="0.4.8"
DEFAULTNAME="null"
INCOGNITONAME="hp-windows"
PERSONALIZATEDNAME="iPhone"

HOSTNAMECTL="hostnamectl"

function usage(){
	echo " [i] Usage: "
	echo "       --battery           Print the percent of the battery"
	echo "       --cache-free        Clear cache"
	echo "       --commit            Get random commit message" #took from whatthecommit
	echo "       --help              Display this page"
	echo "       --hostname          Change hostname"
	echo "       --interfaces        Lists all avaiable interfaces"
	echo "       --install           Copy this script in /usr/sbin/"
	echo "       --ip                Check IP"
	echo "       --ipchange          Change LAN IP"
	echo "       --ipforward         Manage ipforward"
	echo "       --macchange         Change MAC Address"
	echo "       --monitor-mode      Enable montor mode"
	echo "       --password          Generate password"
	echo "       --tor               Manage tor" # check http://stackoverflow.com/a/33726166 to configure it.
	echo "       --version           Display version of this script"
	echo ""
}

function am_i_root(){
	if [[ $EUID -ne 0 ]]; then
		echo " [!] No root permission detected [!]"
		echo " [i] To run this command, you should be root"
		echo ""
		exit
	fi
}

echo " [+] Jack Hacking Tool Set [+]"
if [ -z "$1" ]; then
	echo " [!] No argument supplied. [!]"
	usage
	exit 1
elif [ "$1" = "--help" ]; then
	usage
	exit 0
elif [ "$1" = "--version" ]; then
	echo "Version $VERSION"
	echo ""
	exit 0
elif [ "$1" = "--battery" ]; then
	now=$(cat /sys/class/power_supply/BAT1/charge_now);
	full=$(cat /sys/class/power_supply/BAT1/charge_full);
	echo "Battery: $((now*100/full))%"
	exit 0
elif [ "$1" = "--ip" ]; then
	if [ -z "$2" ]; then
		echo " [!] Missing argument [!]"
		echo " [i] Usasge:   $0 --ip <lan/wan>"
	elif [ "$2" == "lan" ]; then
		ip address | grep "scope global " | sed -e "s/.*inet//" -e "s/\/.*//"
	elif [ "$2" == "wan" ]; then
		echo -n 'External IP: ' && curl http://checkip.amazonaws.com/ 2>/dev/null
	else
		echo " [!] Wrong argument [!]"
		echo " [i] Usasge:   $0 --ip <lan/wan>"
	fi
elif [ "$1" = "--interfaces" ]; then
	echo " [i] Interfaces avaiable: "
	ifconfig -a | grep -Eo '^[^ ]+' | sed 's/://'
elif [ "$1" = "--tor" ]; then
	if [ -z "$2" ]; then
		echo " [!] Missing argument [!]"
		echo " [i] Usage:   $0 --tor --ip"
		echo " [i]          $0 --tor --switchnode"
	else
		if [ "$2" = "--ip" ]; then
			echo -n 'Exit node: ' && curl --socks5 127.0.0.1:9050 http://checkip.amazonaws.com/ 2>/dev/null
		elif [ "$2" = "--switchnode" ]; then
			echo -n 'Current exit node: ' && curl --socks5 127.0.0.1:9050 http://checkip.amazonaws.com/ 2>/dev/null
			( (echo authenticate '""'; echo signal newnym; echo quit) | nc localhost 9051 ) > /dev/null
			echo -n 'New Exit node: ' && curl --socks5 127.0.0.1:9050 http://checkip.amazonaws.com/ 2>/dev/null
		else
			echo " [!] Wrong argument [!]"
			echo " [i] Usage:   $0 --tor --ip"
			echo " [i]          $0 --tor --switchnode"
		fi
	fi
elif [ "$1" = "--password" ]; then
	if [ -z "$2" ]; then
		echo " [!] Missing argument [!]"
		echo " [i] Usage:   $0 --password <length>"
	else
		< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c$2
		 echo ""
	fi
elif [ "$1" = "--commit" ]; then
	# it was actually easy.
	curl http://whatthecommit.com/index.txt 2>/dev/null
##################################################################
elif [ "$1" = "--install" ]; then
	am_i_root
	SCRIPT=$(readlink -f $0)
	cp $SCRIPT /usr/sbin/jhts
	chmod +x /usr/sbin/jhts
	echo " [i] Installing the script..."
	if [ ! -f /usr/sbin/jhts ]; then
		echo " [!] Error during the copy of the script. [!]"
		echo " [i] Check your permission because I can't copy the script."
	else
		echo " [OK] Script installed"
	fi
	echo ""
	exit 0
##################################################################
elif [ "$1" = "--hostname" ]; then
	am_i_root
	if [ -z "$2" ]; then
		echo " [!] Error. Missing argument [!]"
		echo " [i] Usage: $0 --hostname <default/personalizated/incognito>"
	else
		if [ "$2" = "default" ]; then
			echo " [+] Setting hostname to '$DEFAULTNAME'..."
			$HOSTNAMECTL set-hostname $DEFAULTNAME
		elif [ "$2" = "personalizated" ]; then
			echo " [+] Setting hostname to '$PERSONALIZATEDNAME'..."
			$HOSTNAMECTL set-hostname $PERSONALIZATEDNAME
		elif [ "$2" = "incognito" ]; then
			echo " [+] Setting hostname to '$INCOGNITONAME'..."
			$HOSTNAMECTL set-hostname $INCOGNITONAME
		else
			echo " [+] Setting hostname to '$2'"
			$HOSTNAMECTL set-hostname $2
		fi
	fi
##################################################################
elif [ "$1" = "--cache-free" ]; then
	am_i_root
	free
	echo "[+] Executing 'sync'..."
	sync

	echo "[+] Dropping caches..."
	echo 1 > /proc/sys/vm/drop_caches
	echo 2 > /proc/sys/vm/drop_caches
	echo 3 > /proc/sys/vm/drop_caches

	echo "[+] Clearing Swap..."
	swapoff -a && swapon -a

	if [ -f /etc/redhat-release ]; then
		echo "[+] Executing 'dnf clean all'"
		dnf clean all
	fi
	free
elif [ "$1" = "--macchange" ]; then
	am_i_root
	if [ -z "$2" ]; then
		echo "[!] Error. Missing argument. [!]"
		echo "[i] Usage: $0 --macchange <interface> <mac address>"
		echo "           $0 --macchange random <interface>"
	else
		echo " [i] Changing mac.."
		if [ "$2" = "random" ]; then
			ifconfig $3 down
			newmac=$(printf '40:%02X:%02X:%02X:%02X:%02X' $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] $[RANDOM%256])
			echo "[i] Setting mac to $newmac.."
			ifconfig $3 hw ether $newmac
			ifconfig $3 up
		else
			ifconfig $2 down
			ifconfig $2 hw ether $3
			ifconfig $2 up
		fi
		echo " [ok] Done."
	fi
##################################################################
elif [ "$1" = "--ipchange" ]; then
	am_i_root
	if [ -z "$5" ]; then
		echo "[!] Error. Missing argument. [!]"
		echo "[i] Usage: $0 --ipchange <newip> <netmask> <gateway> <interface>"
	else
		echo "[+] Putting down '$5'..."
		ifconfig $5 down

		echo "[+] Changing ip to '$2'..."
		ifconfig $5 $2 netmask $3 up

		echo "[+] Setting gatway to '$4'..."
		route add default gw $4

		echo "[+] Displaing $5 configuration..."
		echo ""
		ifconfig $5
	fi
##################################################################
elif [ "$1" = "--ipforward" ]; then
	am_i_root
	if [ -z "$2" ]; then
		echo " [!] Error. Missing argument [!]"
		echo " [i] Usage: $0 --ipforward <enable/disable>"
	else
		if [ "$2" = "enable" ]; then
			echo " [+] Enabling ip_forward..."
			echo 1 > /proc/sys/net/ipv4/ip_forward
		elif [ "$2" = "disable" ]; then
			echo " [+] Disabling ip_forward..."
			echo 0 > /proc/sys/net/ipv4/ipp_forward
		fi
	fi
##################################################################
elif [ "$1" = "--monitor-mode" ]; then
	am_i_root
	if [ -z "$2" ]; then
		echo " [!] Error. Missing argument [!]"
		echo " [i] Usage: $0 --monitor-mode <interface>"
		echo " [i]        $0 --monitor-mode -nm <interface>"
		echo " [i]        $0 --monitor-mode --restore <interface>"
	elif [ "$2" = "-nm" ]; then
		if [ -z "$3" ]; then
			echo " [!] Error. Missing argument [!]"
			echo " [i] Usage: $0 --monitor-mode <interface>"
			echo " [i]        $0 --monitor-mode -nm <interface>"
			echo " [i]        $0 --monitor-mode --restore <interface>"
		else
			echo " [+] Changing mac..."
			ifconfig $3 down
			newmac=$(printf '40:%02X:%02X:%02X:%02X:%02X' $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] $[RANDOM%256])
			echo " [+] Setting mac to $newmac"
			ifconfig $3 hw ether $newmac
			echo " [+] Starting monitor mode..."
			iwconfig $3 mode monitor
			ifconfig $3 up
		fi
	elif [ "$2" = "--restore" ]; then
		if [ -z "$3" ]; then
			echo " [!] Error. Missing argument [!]"
			echo " [i] Usage: $0 --monitor-mode <interface>"
			echo " [i]        $0 --monitor-mode -nm <interface>"
			echo " [i]        $0 --monitor-mode --restore <interface>"
		else
			echo " [+] Setting $3 in Managed mode..."
			ifconfig $3 down
			iwconfig $3 mode managed
			ifconfig $3 up
		fi
	else
		echo " [+] Starting monitor mode..."
		ifconfig $2 down
		iwconfig $2 mode monitor
		ifconfig $2 up
	fi
##################################################################
else
	echo " [!] Stupid argument. [!]"
	usage
	exit 1
fi
