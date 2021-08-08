#!/bin/bash

. config.sh

if [[ ! -f google-deployment.yml ]]
then
  perl -p -e 's/\$\{([^}]+)\}/defined $ENV{$1} ? $ENV{$1} : $&/eg' < google-deployment.yml.tpl > google-deployment.yml
fi

gcloud deployment-manager deployments create $COMPUTE_VM_NAME --config google-deployment.yml

while [[ -z `gcloud compute instances list | grep mcs | grep RUNNING` ]];
do
  sleep 5
done

gcloud compute scp command.sh config.sh daemon.sh install.sh server.properties.tpl startup-script.sh start.sh shutdown-script.sh stop.sh eula.txt mcs:~/
gcloud compute ssh mcs --command="sudo bash install.sh"