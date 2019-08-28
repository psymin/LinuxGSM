#!/bin/bash
# LinuxGSM command_postconsole.sh function
# Author: psymin
# Contributor: psymin
# Website: https://linuxgsm.com
# Description: Like postconsole log but for console log

local commandname="POSTCONSOLE"
local commandaction="Postconsole"
local function_selfname="$(basename "$(readlink -f "${BASH_SOURCE[0]}")")"

# Set posttarget to the appropriately-defined post destination.

# The options for posttarget are:
# The default destination - hastebin
# posttarget="https://hastebin.com"
#
# Secondary destination - pastebin
# posttarget="http://pastebin.com
#
# Third option - leave on the filesystem
# posttarget=
#
# All of these options can be specified/overridden from the top-level
# invocation, as in:
#  rustserver@gamerig:~$ posttarget="http://pastebin.com" ./rustserver pd
# to post to pastebin, or
#  rustserver@gamerig:~$ posttarget= ./rustserver pd
# to leave the output on the filesystem.
posttarget=${posttarget="https://hastebin.com"}

# For pastebin, you can set the expiration period.
# use 1 week as the default, other options are '24h' for a day, etc.
# This, too, may be overridden from the command line at the top-level.
postexpire="${postexpire="30D"}"

postconsolelog="log/console/wfserver-console.log"

if [ "${posttarget}" == "http://pastebin.com" ] ; then
	fn_print_dots "Posting console to pastbin.com for ${postexpire}"
	# grab the return from 'value' from an initial visit to pastebin.
	csrftoken=$(${curlpath} -s "${posttarget}" |
					sed -n 's/^.*input type="hidden" name="csrf_token_post" value="\(.*\)".*$/\1/p')
	#
	# Use the csrftoken to then post the content.
	#
	link=$(${curlpath} -s "${posttarget}/post.php" -D - -F "submit_hidden=submit_hidden" \
				-F "post_key=${csrftoken}" -F "paste_expire_date=${postexpire}" \
				-F "paste_name=${gamename} Debug Info" \
				-F "paste_format=8" -F "paste_private=0" \
				-F "paste_type=bash" -F "paste_code=<${postconsolelog}" |
				awk '/^location: / { print $2 }' | sed "s/\n//g")

	 # Output the resulting link.
	fn_print_ok_nl "Posting console to pastbin.com for ${postexpire}"
	pdurl="${posttarget}${link}"
	echo "  Please share the following url for support: ${pdurl}"
elif [ "${posttarget}" == "https://hastebin.com" ] ; then
	fn_print_dots "Posting console to hastebin.com"
	# hastebin is a bit simpler.  If successful, the returned result
	# should look like: {"something":"key"}, putting the reference that
	# we need in "key".  TODO - error handling. -CedarLUG
	link=$(${curlpath} -H "HTTP_X_REQUESTED_WITH:XMLHttpRequest" -s -d "$(<${postconsolelog})" "${posttarget}/documents" | cut -d\" -f4)
	fn_print_ok_nl "Posting console to hastebin.com for ${postexpire}"
	pdurl="${posttarget}/${link}"
	echo "  Please share the following url for support: ${pdurl}"
elif [ "${posttarget}" == "https://termbin.com" ] ; then
	fn_print_dots "Posting console log to termbin.com"
	# the sed is to remove ANSI colors
	link=$(cat "${postconsolelog}" | sed 's/\x1b\[[0-9;]*m//g' | nc termbin.com 9999 | tr -d '\n\0')
	fn_print_ok_nl "Posting console log to termbin.com"
	pdurl="${link}"
	echo "  Please share the following url for support: ${pdurl}"
else
	 fn_print_warn_nl "Review console log in: ${postconsolelog}"
	 core_exit.sh
fi

if [ -z "${alertflag}" ]; then
	core_exit.sh
else
	alerturl="${pdurl}"
fi
