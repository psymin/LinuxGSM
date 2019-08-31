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
        elif [ "${querymethod}" ==  "gsquery" ]; then
                if [ ! -f "${functionsdir}/query_gsquery.py" ]; then
                        fn_fetch_file_github "lgsm/functions" "query_gsquery.py" "${functionsdir}" "chmodx" "norun" "noforce" "nomd5"
                fi
		gs_command="${functionsdir}/query_gsquery.py -a \"${ip}\" -p \"${queryport}\" -e \"${engine}\""
		#gs_output_uniform="${gs_command} 2> /dev/null | sed -e 's/\\\\/\\/g' | sed -e 's/^.*statusResponse.*challenge..//' | sed -e 's/^.challenge..//' | grep -v status | sed -e s/.n\'$//"
		gsarray=$("${gs_command} 2> /dev/null | sed -e 's/\\\\/\\/g' | sed -e 's/^.*statusResponse.*challenge..//' | sed -e 's/^.challenge..//' | grep -v status | sed -e s/.n\'$//")

		declare -A gsq_result
		
#		clients=$(${gs_command} | sed -e s/^.*clients..// | sed -e s/.\n.*//)
#                clients=$(${functionsdir}/query_gsquery.py -a "${ip}" -p "${queryport}" -e "${engine}" | sed -e s/^.*clients..// | sed -e s/.\n.*//)
		players="${clients}"
                querystatus="$?"
		echo "gscmd:	${gs_command}"
		echo "unif:	${gs_output_uniform}"
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
fi

core_exit.sh
