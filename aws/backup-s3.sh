#!/bin/bash
# This script will backup docker/rancher data from the system to AWS S3 using s3cmd and encryption
# Prerequisite is to install s3cmd using apt install s3cmd
# Do Not forget to configure it using s3cmd --configure
# And Do Not forget to create one S3 bucket for each server. The name should be the hostname.
#
# Regarding folder backup, by default for Rancher it is: /opt/rancher and /var/log/rancher/auditlog based on this installation:
# docker run -d --restart=unless-stopped -p 80:80 -p 443:443 -e CATTLE_TLS_MIN_VERSION="1.2" -v /var/log/rancher/auditlog:/var/log/auditlog -e AUDIT_LEVEL=1 -v /opt/rancher:/var/lib/rancher rancher/rancher:latest --acme-domain <rancher-hostname>.<domain>.<ext>
#
# Regarding docker data files, by default all data are stored in: /mount/k8s and some others can be used
#
potentialdatadirs="/mount/k8s /opt/rke/etcd-snapshots /opt/rancher /var/log/rancher/auditlog /etc/ceph /etc/cni /etc/kubernetes /opt/cni /opt/rke /run/secrets/kubernetes.io /run/calico /run/flannel /var/lib/calico /var/lib/etcd /var/lib/cni /var/lib/kubelet /var/lib/rancher/rke/log /var/log/containers /var/log/pods /var/run/calico"
#
# Prepare backup filename to be used
backupfilename=/tmp/docker-data-backup-$HOSTNAME-$(date +%F_%H:%M:%S).tar.gz
#
# List running containers in Docker and store them in a file
docker ps -q > /tmp/docker_ids
#
# Stop all containers based on the file
docker stop -t 60 $(cat /tmp/docker_ids)
#
# Backup all data using Tar
tar zcvf $backupfilename $potentialdatadirs
#
# Start all previously stopped containers
docker start $(cat /tmp/docker_ids)
#
# Send backup file in AWS S3
s3cmd -e put $backupfilename s3://$HOSTNAME
#
