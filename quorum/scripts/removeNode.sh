#!/bin/sh

echo "Enter the number of to be removed (e.g. 1):"
read NODE_REMOVE

NODES_LENGTH=$(yq eval '.nodes | length' ../values.yaml)
NODE_NAME="node$NODE_REMOVE"

yq eval "del(.nodes.$NODE_NAME)" -i ../values.yaml

echo "New values.yaml: "
yq eval .nodes ../values.yaml

cd ../.. && helm upgrade nnodes quorum -n quorum-network && cd quorum/scripts/