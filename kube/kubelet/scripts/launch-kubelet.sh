#!/usr/bin/env bash
if [[ "${MASTER}" == "true" ]]
then
  /opt/bin/kubelet \
    --docker-endpoint=unix:///var/run/weave/weave.sock \
    --api-servers=http://127.0.0.1:8080 \
    --register-schedulable=true \
    --register-node=true \
    --allow-privileged=true \
    --config=/etc/kubernetes/manifests \
    --hostname-override=${NODE_IP} \
    --cluster-dns=10.16.0.3 \
    --cluster-domain=${DOMAIN} \
    --tls-cert-file=/etc/kubernetes/ssl/node.pem \
    --tls-private-key-file=/etc/kubernetes/ssl/node-key.pem \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    @*
else
  echo "Waiting for Kubernetes..."
  until curl -k -s https://10.16.0.1
  do
    echo "Trying: https://10.16.0.1"
    sleep 10
  done
  curl -s -XPOST ${PIDALIO_URL}/certs/node\?token\=${PIDALIO_TOKEN}\&id=${NODE_ID}\&ip=${NODE_IP}\&os=linux\&arch=amd64
#      --cloud-provider=openstack \
#      --cloud-config=/etc/kubernetes/cloud.conf \
  /opt/bin/kubelet \
    --docker-endpoint=unix:///var/run/weave/weave.sock \
    --api-servers=https://10.16.0.1 \
    --register-node=false \
    --node-labels=mode=SchedulingDisabled \
    --allow-privileged=true \
    --config=/etc/kubernetes/manifests \
    --hostname-override=${NODE_IP} \
    --cluster-dns=10.16.0.3 \
    --cluster-domain=${DOMAIN} \
    --tls-cert-file=/etc/kubernetes/ssl/node.pem \
    --tls-private-key-file=/etc/kubernetes/ssl/node-key.pem \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    @*
fi