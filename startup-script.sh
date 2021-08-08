#!/bin/bash

cd "${0%/*}"

. config.sh

gcloud dns record-sets update $DOMAIN_NAME -z $DNS_ZONE --type=A --rrdatas=$(gcloud compute instances describe $COMPUTE_VM_NAME --zone=$COMPUTE_ZONE | yq eval .networkInterfaces[0].accessConfigs[0].natIP -) --ttl=$DOMAIN_TTL
./start.sh
