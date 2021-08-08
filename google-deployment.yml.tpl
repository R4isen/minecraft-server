resources:
- type: compute.v1.instance
  name: mcs
  properties:
    zone: ${COMPUTE_ZONE}
    machineType: projects/${GCLOUD_PROJECT}/zones/${COMPUTE_ZONE}/machineTypes/${COMPUTE_VM_TYPE}
    disks:
    - deviceName: "mcs"
      type: PERSISTENT
      boot: true
      mode: "READ_WRITE"
      autoDelete: false
      initializeParams:
        sourceImage: ${COMPUTE_VM_IMAGE}
        diskType: projects/${GCLOUD_PROJECT}/zones/${COMPUTE_ZONE}/diskTypes/${COMPUTE_VM_DISK_TYPE}
        diskSizeGb: 10
    networkInterfaces:
    - network: projects/${GCLOUD_PROJECT}/global/networks/default
      subnetwork: projects/${GCLOUD_PROJECT}/regions/${COMPUTE_REGION}/subnetworks/default
      accessConfigs:
      - name: External NAT
        type: ONE_TO_ONE_NAT
    scheduling:
      automaticRestart: false
      onHostMaintenance: TERMINATE
      preemptible: true
    serviceAccounts:
    - email: ${COMPUTE_VM_SERVICE_ACCOUNT}
      scopes:
      - https://www.googleapis.com/auth/cloud-platform
    tags:
      items:
      - mcs