#!/bin/bash
#ToDo: get hostname from terraform ENV?
ssh tf@vyos-cloud.intern.mungard.de "/opt/vyatta/bin/vyatta-op-cmd-wrapper show system commit | head -1 | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}.*$' > /home/tf/last_manual_commit.txt" 2>/dev/null || >&2 echo "Encountered error in SSH connection to vyos-cloud"
