#!/bin/bash

#ToDo: get hostname from terraform ENV?
export ARG=$(ssh tf@vyos-cloud.intern.mungard.de "cat /home/tf/last_manual_commit.txt") \
	|| >&2 echo "Encountered error in SSH connection to vyos-cloud"

export REVNUM=$(ssh tf@vyos-cloud.intern.mungard.de "/opt/vyatta/bin/vyatta-op-cmd-wrapper show system commit" | grep "$ARG" | grep -Eo '^[0-9]+') \
	|| >&2 echo "Encountered error in SSH connection to vyos-cloud"

# rollback works this way, need to check why
let "REVNUM=REVNUM+1"

#ToDo: remove last_manual_commit.txt

#https://explainshell.com/explain?cmd=ssh+-tt
ssh -tt tf@vyos-cloud.intern.mungard.de "yes | sudo /opt/vyatta/sbin/vyatta-config-mgmt.pl --action rollback --revnum=$REVNUM" \
        || >&2 echo "Encountered error in SSH connection to vyos-cloud"
