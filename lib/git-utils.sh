#!/bin/bash

REALGIT=/usr/bin/git

if [ -n "${SSH_KEY_PATH}" ]; then
export GIT_SSH_COMMAND="/usr/bin/ssh -i ${SSH_KEY_PATH} -o IdentitiesOnly=yes -F /dev/null"
fi

git_once()
{
	$REALGIT $* 2>&1 | tee -a "${LOGDIR}/git-`hostname`-log.txt"
}

git_retry()
{
	RETRIES=10
	DELAY=10
	COUNT=1
	while [ $COUNT -lt $RETRIES ]; do
		git_once $*
		if [ $? -eq 0 ]; then
			RETRIES=0
			break
		fi
		let COUNT=$COUNT+1
		sleep $DELAY
	done
}

git_repo_exists()
{
	local repo_url=$1
	$REALGIT ls-remote ${repo_url} >/dev/null 2>&1
	local retval=$?
	if [ $retval -eq 0 ];then
		return 0
	else
		return 1
	fi
}
