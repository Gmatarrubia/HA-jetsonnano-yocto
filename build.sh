#!/bin/bash

repoPath="$(dirname $(realpath ${BASH_SOURCE[0]}))"
source extraFunctions.sh

# Script arguments handle
__verbose=
__bitbake_cmd=()
__only_shell=
__parallel_limit=
__wifi_settings_interactive=
__cores=
__conf_name=nano-sd
__extra_conf_files=
__cache_server_path="/work/sstate"
__source_yml_path="${repoPath}/targets/sources"
__features_yml_path="${repoPath}/targets/features"
__sstate_cache_file="${__source_yml_path}/use-sstate-cache.yml"
__debug_conf_file="${__features_yml_path}/debug.yml"
__cve_conf_file="${__features_yml_path}/cve.yml"
__audit_conf_file="${__features_yml_path}/audit.yml"

while (( $# )); do
    case ${1,,} in
        -v|--verbose)
            __verbose=1
            echo "Verbose output enabled"
            ;;
        -b|--bitbake)
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
            __extra_conf_files="${__extra_conf_files}:${__debug_conf_file}"
            ;;
        -cve|--cve)
            __extra_conf_files="${__extra_conf_files}:${__cve_conf_file}"
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
export CONF_FILE="${repoPath}/targets/${__conf_name}.yml"
export KAS_BUILD_DIR="${repoPath}/build_${__conf_name}"
test -f "${HOME}/.git-credentials" && export GIT_CREDENTIAL_HELPER="${HOME}/.git-credentials"
test -f "${HOME}/.netrc" && export NETRC_FILE="${HOME}/.netrc"
#test -f "${HOME}/.ssh/id_rsa" && export SSH_PRIVATE_KEY_FILE="${HOME}/.ssh/id_rsa"
export DL_DIR="${repoPath}/dl"
export SSTATE_DIR="${repoPath}/sstate"
export SHELL="/bin/bash"
rm -rf "${__conf_name}"/targets/*

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

if [ -n "$(ls -A $__cache_server_path)" ]; then
    __extra_conf_files="${__extra_conf_files}:${__sstate_cache_file}"
fi

# Start environment in shell mode
if [ -n "${__only_shell}" ]
then
    kas shell -E "${CONF_FILE}${__extra_conf_files}"
    exit 0
fi

if [ -z "${__bitbake_cmd[*]}" ]
then
    time kas build "${CONF_FILE}${__extra_conf_files}"
else
    echo "Executing command: ${__bitbake_cmd[*]}"
    time kas shell "${CONF_FILE}${__extra_conf_files}" -c "${__bitbake_cmd[*]}"
fi
