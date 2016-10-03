#!/usr/bin/env bash
i=0
until curl -m 5 http://localhost:8080/healthz || [[ $i == 5 ]]
do
    echo "Waiting for master to be ready"
    sleep 10
    i=$(expr $i + 1)
done
if [[ $i == 5 ]]; then exit 1; fi
# Initialize Kubernetes Addons
/opt/bin/kubectl create -f /etc/kubernetes/descriptors/dns
# Initialize Ceph
if [[ "${CEPH}" == "True" ]]
then
    /opt/pidalio/kube/kubelet/scripts/ceph/install-ceph.sh
    /opt/bin/kubectl create -f /etc/kubernetes/descriptors/ceph --namespace=ceph
fi
# Initialize Monitoring
if [[ "${MONITORING}" == "True" ]]
then
    /opt/bin/kubectl create namespace monitoring
    /opt/bin/kubectl create -f /etc/kubernetes/descriptors/monitoring --namespace=monitoring
fi
# Initialize Toolbox
ssh-keygen -t rsa -f key
/opt/bin/kubectl create secret generic toolbox --from-file=ssh-privatekey=key --from-file=ssh-publickey=key.pub
rm -f key key.pub
# Openstack secrets
source /etc/openstack.env
OS_USERNAME=$(echo -n $OS_USERNAME | base64)
OS_PASSWORD=$(echo -n $OS_PASSWORD | base64)
OS_AUTH_URL=$(echo -n $OS_AUTH_URL | base64)
OS_TENANT_NAME=$(echo -n $OS_TENANT_NAME | base64)
cat <<EOF | kubectl create -f -
  apiVersion: v1
  kind: Secret
  metadata:
    name: openstack
  type: Opaque
  data:
    auth: $OS_AUTH_URL
    tenant: $OS_TENANT_NAME
    password: $OS_PASSWORD
    username: $OS_USERNAME
EOF
/opt/bin/kubectl create -f /etc/kubernetes/descriptors/toolbox/
# Ceph Initialize
/opt/bin/rbd -m ceph-mon.ceph list
/opt/bin/rbd -m ceph-mon.ceph create toolbox --size=10G
exit 0
