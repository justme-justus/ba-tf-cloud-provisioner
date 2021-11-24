#!/bin/bash

# script for base redeployment
# start with $ screen -d -m ./redeploy.sh

terraform destroy -auto-approve
./deploy.sh
