#!/bin/bash
# LinuxGSM command_safe_update.sh function
# Author: psymin
# Website: https://runlinux.net
# Description: Checks if servers are empty before updating

local commandname="UPDATE"
local commandaction="Update"
local function_selfname="$(basename "$(readlink -f "${BASH_SOURCE[0]}")")"

check.sh
check_ip.sh


# both methods work with wfserver
# set here for verifying and testing
# preferring gsquery for reduced deps
# edit: changing to gamedig only for merging to warfork-stable

#querymethod="gsquery"
querymethod="gamedig"

check_status.sh
if [ "${status}" != "0" ]; then

        if [ "${querymethod}" ==  "gamedig" ]; then
                query_gamedig.sh
		players=${gdplayers}
	fi

	if [ "${players}" == "0" ]; then
		echo "No players connected, update is safe to perform."	
		#update_steamcmd.sh
		command_update.sh
		
	else
		echo "Players connected (${players}) update not being attempted."
	fi
else
	echo "Server failed status check."
	echo "Doing regular update."
	command_update.sh
fi

core_exit.sh
