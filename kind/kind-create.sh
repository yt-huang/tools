#!/usr/bin/env bash

set -o nounset 
set -o pipefail
set -x

hostPort=$1
cluster-name=$2
image=${3:-kindest/node:v1.29.0}
function update_host(){
        sed -i "s/hostPort:.*/hostPort: ${hostPort}/g" kind.host.yaml
        sed -i "s#image:.*#image: ${image}#g" kind.host.yaml
}

function create_kind_cluster(){
        kind create cluster --name ${cluster-name} --kubeconfig=./${cluster-name}.yaml --image=${image} --config=kind.host.yaml

}
update_host
create_kind_cluster