#!/usr/bin/env bash

script_name="$(basename $0)"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

error_exit() {
    echo "Error: $1"
    exit 1
}

apply() {
    kubectl create ns common-gw
    kubectl create ns httpbin

    kubectl label ns httpbin shared-gateway=true --overwrite || true

    kubectl apply -n httpbin -f $dir/httpbin-deploy.yaml
    kubectl apply -n httpbin -f $dir/httpbin-upstream.yaml

    envsubst < <(cat $dir/common-gw.yaml) | kubectl apply -n common-gw -f -
    kubectl apply -n common-gw -f $dir/http-listener-option.yaml
    kubectl apply -n common-gw -f $dir/listener-option.yaml
    envsubst < <(cat $dir/httpbin-route.yaml) | kubectl apply -n httpbin -f -
}

delete() {
    kubectl delete ns httpbin
    kubectl delete ns common-gw
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
    local source_name=$1
    shift
    local apply_func=$1
    shift
    local delete_func=$1
    shift

    if [[ $# -eq 0 ]]; then
        echo "No options provided, check help below"
        cmdline_arg_processor_help $source_name
    fi

    while getopts had-: OPT; do
        if [ "$OPT" = "-" ]; then
            OPT="${OPTARG%%=*}"
        fi
        case "$OPT" in
        a | apply)
            $apply_func
            break
            ;;
        d | delete)
            $delete_func
            break
            ;;
        h | help)
            cmdline_arg_processor_help $source_name
            ;;
        \?)
            exit 2
            ;;
        *)
            error_exit "Illegal option --$OPT"
            cmdline_arg_processor_help $source_name
            ;;
        esac
    done
}

cmdline_arg_processor $script_name apply delete $1
