#!/bin/bash

function usage() {
    cat <<USAGE

Usage:
    $0 [command] [options]

Commands:
    run          Run db
    stop 	 Stop db
Description:
    database - script that just run and stop db

USAGE
    exit 1
}




# ==============================================
# COMMAND SWITCHER

case $1 in
# run db
run)
    shift 1;
    while getopts "dh" opt; do
        case $opt in
        d) DETACHED=1 ;;
        \?) echo "Invalid option -$OPTARG"
            exit 1
             ;;
        esac
    done

    shift $((OPTIND - 1))

    if [[ $DETACHED ]]; then
        echo "STARTING..."
        docker compose up -d
    else 
        docker compose up
    fi
    ;;

# stop db
stop)
    shift 1;
    docker compose down
    docker volume rm db-data
    ;;

# show help
--help)
    usage
    ;;
help)
    usage
    ;;
-h)
    usage
    ;;

# All invalid commands will invoke usage page
*)
    usage
    ;;
esac