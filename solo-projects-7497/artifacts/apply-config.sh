#!/usr/bin/env bash

SCRIPT_NAME="`basename $0`"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

error_exit() {
    echo "Error: $1"
    exit 1
}

apply() {
    kubectl create ns apps

    kubectl apply -n apps -f $DIR/httpbin-deploy.yaml

    envsubst < <(cat $DIR/main-gw.yaml) | kubectl apply -f -
    kubectl apply -f $DIR/listener-option.yaml
    kubectl apply -f $DIR/jwks-upstream.yaml
    envsubst < <(cat $DIR/route-option.yaml) | kubectl apply -f -
    envsubst < <(cat $DIR/main-route.yaml) | kubectl apply -f -
}

delete() {
    kubectl delete -f $DIR/listener-option.yaml
    kubectl delete -f $DIR/jwks-upstream.yaml
    kubectl delete -f $DIR/route-option.yaml
    kubectl delete -f $DIR/main-gw.yaml
    kubectl delete -f $DIR/main-route.yaml

    kubectl delete ns apps
}

cmdline_arg_processor_help() {
    local caller=$1
    cat <<EOF
usage: $caller

-a  | --apply       Apply the artifacts
-d  | --delete      Clean the artifacts
-h  | --help        Usage
EOF

    exit 1
}

cmdline_arg_processor() {
    local source_name=$1; shift
    local apply_func=$1; shift
    local delete_func=$1; shift

    local short=a,d,h
    local long=apply,delete,help
    local opts=$(getopt -a -n "setup.sh" --options $short --longoptions $long -- "$@")

    eval set -- "$opts"

    local opt=$1; shift

    if [[ $opt == "" ]]; then
        echo "Unrecognized option provided, check help below"
        cmdline_arg_processor_help $source_name
    fi

    while :; do
        case "$opt" in
        -a | --apply)
            $apply_func
            break
            ;;
        -d | --delete)
            $delete_func
            break
            ;;
        -h | --help)
            cmdline_arg_processor_help $source_name
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unexpected option: $opt"
            cmdline_arg_processor_help $source_name
            ;;
        esac
    done
}

cmdline_arg_processor $SCRIPT_NAME apply delete $1