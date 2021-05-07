#!/bin/bash

set -Eeuo pipefail

cleanup() {
    echo "Done."
}

# make sure not to leave files around in the source tree
trap 'cleanup' EXIT SIGTERM SIGINT ERR

declare USER="${1:-openlabs-admin}"

if [[ -z "${USER}" ]]; then
    echo "Must specify a user"
    exit 1
fi

echo "Creating htpasswd secret from the htpasswd file in the openshift-config namespace"
oc create secret generic htpasswd -n openshift-config --from-file=<(echo 'openlabs-admin:$2y$05$cUvHv2DeIVns7hSG/Ne2E.LKEDBv7VXUGzy7wdjZ0jx5Yoy.b3vl2')

cat <<EOF | oc apply -n openshift-operators -f - 
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: Local Password 
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpasswd
EOF

echo "Adding ${USER} as a cluster-admin"
oc adm policy add-cluster-role-to-user cluster-admin ${USER}