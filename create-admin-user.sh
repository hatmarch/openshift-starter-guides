#!/bin/bash

set -Eeuo pipefail

cleanup() {
    rm htpasswd || true
}

# make sure not to leave files around in the source tree
trap 'cleanup' EXIT SIGTERM SIGINT ERR

declare USER="${1:-openlab-admin}"
declare PASSWORD="${2:-openlab-admin}"

if [[ -z "${USER}" ]]; then
    echo "Must specify a user"
    exit 1
fi

if [[ -z "${PASSWORD}" ]]; then
    echo "Must specify a password"
    exit 1
fi

# create htpasswd
touch htpasswd

htpasswd -Bb htpasswd "${USER}" "${PASSWORD}"

echo "Creating htpasswd secret from the htpasswd file in the openshift-config namespace"
oc --user=admin create secret generic htpasswd --from-file=htpasswd -n openshift-config

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

echo "Admin user $USER configured with password ${PASSWORD}"