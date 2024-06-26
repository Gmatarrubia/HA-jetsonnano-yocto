#!/bin/bash

repoPath="$(dirname $(realpath ${BASH_SOURCE[0]}))"
source checkFunctions.sh

# Script arguments handle
__verbose=
__bitbake_cmd=()
__only_shell=
__wifi_settings_interactive=
__debug=
__parallel_limit=
__cores=
__conf_name=qemu

while (( $# )); do
    case ${1,,} in
        -v|--verbose)
            __verbose=1
            echo "Verbose output enabled"
            ;;
        -bc|--bitbake-cmd)
            shift
            __bitbake_cmd+=("${@}")
            echo Custom bitbake command: "${__bitbake_cmd[@]}"
            ;;
        --shell)
            __only_shell=1
            echo "Only shell mode"
            ;;
        -m|--machine)
            __conf_name="$2"
            shift
            ;;
        -wi|--wifi)
            __wifi_settings_interactive=1
            ;;
        -d|--debug)
            __debug=":${repoPath}/conf/debug.yml"
            ;;
        -j)
            __parallel_limit=":${repoPath}/conf/parallel.yml"
            __cores="$2"
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
    esac
    shift
done

# Start configuration
export CONF_FILE="${repoPath}/conf/${__conf_name}.yml"
export KAS_BUILD_DIR="${repoPath}/${__conf_name}"
export DL_DIR="${repoPath}/dl"
export SSTATE_DIR="${repoPath}/sstate"
export SHELL="/bin/bash"
rm -rf "${__conf_name}"/conf/*

# Check availability of the kas tool
check_kas

# Check if config file exists
if [ ! -f "${CONF_FILE}" ]
then
    echo "Machine ${__conf_name} unknown"
    echo "Config file doesn't exist: ${CONF_FILE}"
    exit 2
fi

# Check if sources were downloaded
if [ ! -d "${repoPath}/sources" ]
then
    kas checkout "${CONF_FILE}"
fi

# Set WIFI configuration
if [ -n "${__wifi_settings_interactive}" ]
then
    read -p "Enter your ssid: " WIFISSID
    read -p "Enter your pass: " WIFIPASS
fi
if [ -n "${WIFISSID}" ] && [ -n "${WIFIPASS}" ]
then
    pushd ./meta-custom/recipes-connectivity/wpa-supplicant/files || return
    sed -i -E "s/ssid=\".*\"/ssid=\"$WIFISSID\"/g" ./*
    sed -i -E "s/psk=\".*\"/psk=\"$WIFIPASS\"/g" ./*
    popd || return
fi

# Enable parallel configuration
if [ -n "${__parallel_limit}" ]
then
    # Replaces current value in file
    sed -i -E "s|PARALLEL_MAKE = \"-j.*\"|PARALLEL_MAKE = \"-j$__cores\"|g" "${__parallel_limit#?}"
    sed -i -E "s|BB_NUMBER_THREADS = \".*\"|BB_NUMBER_THREADS = \"$__cores\"|g" "${__parallel_limit#?}"
fi

# Verbose option enables more detallied output
if [ -n "${__verbose}" ]
then
    echo '***************************************'
    kas shell "${CONF_FILE}" -c "bitbake-layers show-layers"
    echo '***************************************'
    kas shell "${CONF_FILE}" -c "bitbake -e virtual/kernel | grep '^PV'"
    kas shell "${CONF_FILE}" -c "bitbake -e virtual/kernel | grep '^PN'"
    echo '***************************************'
    kas shell "${CONF_FILE}" -c "bitbake -e" > bb.environment
fi

# Start environment in shell mode
if [ -n "${__only_shell}" ]
then
    kas shell -E "${CONF_FILE}${__debug}"
    exit 0
fi


if [ -z "${__bitbake_cmd[*]}" ]
then
    time kas build "${CONF_FILE}${__debug}${__parallel_limit}"
else
    echo "Executing command: ${__bitbake_cmd[*]}"
    time kas shell "${CONF_FILE}${__debug}${__parallel_limit}" -c "${__bitbake_cmd[*]}"
fi
