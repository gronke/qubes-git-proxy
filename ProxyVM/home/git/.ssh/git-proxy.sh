#!/bin/sh

REMOTE="$1"
GIT_COMMAND="$(echo $SSH_ORIGINAL_COMMAND | cut -d' ' -f1)"
GIT_REPO="$(echo $SSH_ORIGINAL_COMMAND | cut -d' ' -f2 | sed s/\'//g)"

ACL_FILE="$HOME/.ssh/git-proxy.acl"

case "$GIT_COMMAND" in
	"git-upload-pack")
		;;
	"git-receive-pack")
		;;
	*)
		# other commands not allowed
		exit 1
		;;
esac

grant_permission() {
	touch "$ACL_FILE"

	DOMAIN=""	
	OUTPUT=""
	while IFS= read -r line
	do
		if echo "$line" | grep -Eq '^\[.*\]\s*$'; then
			if [ "$DOMAIN" != "" ]; then
				# empty line between multiple sections
				SPACING="${OUTPUT}\n"
			else
				SPACING=""
			fi
			DOMAIN="$(echo $line | tr -d '[] ')"
			if [ "$DOMAIN" = "$QREXEC_REMOTE_DOMAIN" ]; then
				# add the requested repo after section header
				OUTPUT="${OUTPUT}${SPACING}${line}\n${GIT_REPO}\n"
			       continue	
			fi
		elif echo "$line" | grep -Eq '^\s+$'; then
			# skip empty lines
			continue
		elif [ "$DOMAIN" = "$QREXEC_REMOTE_DOMAIN" ] && [ "$line" = "$GIT_REPO" ]; then
			# skip existing
			continue
		fi
		# include line
		OUTPUT="${OUTPUT}${line}\n"
	done < "$ACL_FILE"
	echo "$OUTPUT" > "$ACL_FILE"
}

ask_permission()
{
	ESCAPED_GIT_REPO="$(printf $GIT_REPO | sed s/\\//+/)"
	if qrexec-client-vm "$QREXEC_REMOTE_DOMAIN" "git.Allow+${ESCAPED_GIT_REPO}" 2> /dev/null
	then
		grant_permission
	else
		exit 1
	fi	
}

if [ ! -f "$ACL_FILE" ]; then
	ask_permission
fi

ALLOWED=0
DOMAIN=""
while IFS= read -r line
do
	if echo "$line" | grep -Eq '^\[.*\]\s*$'; then
		DOMAIN="$(echo $line | cut -d':' -f1)"
		continue
	elif echo "$line" | grep -Eq '^\s*(#.*)?\s*$'; then
		# skip comments and empty lines
		continue
	elif [ "$DOMAIN" = "" ]; then
		# skip lines without prior qubes domain
	       continue	
	elif [ "$line" = "$GIT_REPO" ]; then
		ALLOWED=1
		break
	fi
done < "$ACL_FILE"

if [ "$ALLOWED" -ne 1 ]; then
	ask_permission
fi

ssh -q "$REMOTE" -- "$SSH_ORIGINAL_COMMAND"
