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

querymethod="gsquery"
#querymethod="gamedig"

check_status.sh
if [ "${status}" != "0" ]; then

        if [ "${querymethod}" ==  "gamedig" ]; then
                query_gamedig.sh
		players=${gdplayers}
        elif [ "${querymethod}" ==  "gsquery" ]; then
                if [ ! -f "${functionsdir}/query_gsquery.py" ]; then
                        fn_fetch_file_github "lgsm/functions" "query_gsquery.py" "${functionsdir}" "chmodx" "norun" "noforce" "nomd5"
                fi
		#gs_command="${functionsdir}/query_gsquery.py -a \"${ip}\" -p \"${queryport}\" -e \"${engine}\""
		#echo $gs_command
		gs_output="$(${functionsdir}/query_gsquery.py -a ${ip} -p ${queryport} -e ${engine})"
		#echo "is this where?"
		#echo $gs_output
		echo $gs_output | grep "xffstatusResponse" 1> /dev/null
		if [[ $? -eq 0 ]]
		then
		# we have a match on the xffstatusResponse 
			#echo match
			var=$(echo ${gs_output} | sed -e 's/^OK: b.*statusResponse..//' | grep challenge | sed -e 's/\\n.$//' | sed -e 's/\\\\\\\\/\\\\0\\\\/g' | sed -e 's/\\\\/\\/g' | sed -e 's/^.*version/version/')
		else
			# we don't have a matchon xffstatusResponse
			#echo nomatch
			var=$(echo ${gs_output} | grep challenge | sed -e 's/\\\\/\\0\\/g' | sed -e 's/^.*version/version/')
		fi


		# make arrays

		IFS='\\' read -r -a array <<< "$var"
		i=0
		declare -A gsquery
		while [ $i -lt ${#array[@]} ]
		do
			gsquery[${array[$i]}]=[${array[$i+1]}]
			#echo "${array[$i]} ${array[$i+1]}"
			i=$[$i+2]
		done

#		players=${gsquery[clients]}
#		echo "variable: ${gsquery[clients]}"

        	if [[ ${gsquery[bots]} == ${gsquery[clients]} ]]
	        then
			echo "Onlybots, safe to update"
			players="0"
		elif [[ ${gsquery[clients]} == "[0]" ]]
		then
			echo "No players."
			players="0"
		else
			players="1"
		fi



	fi

	if [ "${players}" == "0" ]; then
		echo "No players connected, update is safe to perform."	
		command_update.sh
		
	else
		echo "Players connected, update not being attempted."
	fi
else
	echo "Server failed status check."
	echo "Performing regular update."
	command_update.sh
fi

core_exit.sh
