#!/bin/bash

# Deployment script to circumvent terraform bug: https://github.com/hashicorp/terraform-provider-aws/issues/11293
# checks how many bgp routes are in FIB, if < 2 per prefix -> redeploy
# if nothing was grepped then we have another problem -> stop

# start with $ screen -d -m ./deploy.sh

#Better: get current networks from IPAM after terraform apply
PREFIX_AZURE="10.32.0.0"
PREFIX_AWS="10.33.0.0"
# max. n tries, be nice to the cloud APIs
MAX_RETRY=3

for i in `seq 1 $MAX_RETRY`; do

	echo "Base deployment: $i. try..."
	terraform apply -auto-approve

	#wait 60 seconds for route convergence
	sleep 60
	
	# Azure CIDR, ignore subnet mask
	ROUTE_COUNT_AZURE=`ssh tf@vyos-cloud.intern.mungard.de "vtysh -c \"sh ip bgp $PREFIX_AZURE\"" 2>/dev/null |\
		grep -Eo '[0-9]+ available' | grep -Eo '[0-9]+'` || \
		{ echo "No Azure routes found, deployment is broken! exit 10..."; exit 10; }
	# AWS CIDR
	ROUTE_COUNT_AWS=`ssh tf@vyos-cloud.intern.mungard.de "vtysh -c \"sh ip bgp $PREFIX_AWS\"" 2>/dev/null |\
		grep -Eo '[0-9]+ available' | grep -Eo '[0-9]+'` || \
		{ echo "No AWS routes found, deployment is broken! exit 20..."; exit 20; }
	
	if [[ "$ROUTE_COUNT_AZURE" -lt 2 || "$ROUTE_COUNT_AWS" -lt 2 ]]; then

		if [ "$i" -eq "$MAX_RETRY" ]; then
			echo "Deployment not successful after $i tries, exit 1..."
			exit 1
		fi

		echo "Deployment not successful, rebuilding..."

		terraform destroy -auto-approve
		continue
	fi

	#deployment successful
	echo "$i. deployment successful, exit 0..."
	break
done
