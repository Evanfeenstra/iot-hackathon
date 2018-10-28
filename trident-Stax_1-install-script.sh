#!/bin/sh
SCRIPT_NAME="${0}"
DOCKER_COMPOSE_FILE='trident-stax-1-docker-compose.yml'
DOCKER_COMPOSE_URL='https://demo.api.stax.tlabs.cloud/namespaces/trident/projects/Stax_1/docker-compose'
export COMPOSE_IGNORE_ORPHANS=true

get_default_values() {
    export REGISTRY_URL=${REGISTRY_URL:-'registry.hashstax.eu'}
    export REGISTRY_USER=${REGISTRY_USER:-'stax'}
    export REGISTRY_PASS=${REGISTRY_PASS:-'stax'}
    export SPRING_RABBITMQ_HOST=${SPRING_RABBITMQ_HOST:-'185.27.183.105'}
    export SPRING_RABBITMQ_PORT=${SPRING_RABBITMQ_PORT:-'5672'}
    export SPRING_RABBITMQ_USERNAME=${SPRING_RABBITMQ_USERNAME:-'admin'}
    export SPRING_RABBITMQ_PASSWORD=${SPRING_RABBITMQ_PASSWORD:-'xau0Jisoonea5aiV'}
    export EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=${EUREKA_CLIENT_SERVICEURL_DEFAULTZONE:-'https://demo.sd.stax.tlabs.cloud/eureka/'}
    export SPRING_CLOUD_CLIENT_IPADDRESS=${SPRING_CLOUD_CLIENT_IPADDRESS:-127.0.0.1}
    export GATEWAY_PORT=9191
    export IOTA_NODE_API_PORT=14265
    export IOTA_NODE_UDP_PORT=14777
    export IOTA_NODE_TCP_PORT=15777


}

usage() {
    echo
    echo "Usage:"
    echo "  ${SCRIPT_NAME} [OPTIONS...] [COMMAND] [ARGUMENTS...]"
    echo
    echo "Running script with no additional arguments will install and start MESH Node"
    echo
    echo "Options:"
    echo "  -h, --help                      print usage"
    echo "  -i, --interactive               enter interactive mode"
    echo "  -s, --skip-registry-auth        skip docker registry authentication"
    echo '  -y, --assume-yes                remove existing docker volumes and networks used by MESH Node before installing or after removing it'
    echo '  -n, --assume-no                 preserve existing docker volumes and networks used by MESH Node before installing or after removing it'
    echo
    echo "Commands:"
    echo "  install                 install and start all docker containers of MESH Node"
    echo "  start                   start all docker containers of MESH Node"
    echo "  ps                      list statuses of docker containers in MESH Node"
    echo "  status CONTAINER        show status of docker container"
    echo "  stop                    stop all docker containers of MESH Node"
    echo "  remove                  stop and remove all docker containers, volumes and networks of MESH Node"
    echo
    echo "Arguments:"
    echo "  --cacert FILE                   specify certificate file in PEM format to verify the peer during communication with Configuration-Management"
    echo "  --p12cert FILE                  specify certificate file in P12 format to verify the peer during communication with Configuration-Management"
    echo '  --p12pass PASS                  specify password for P12 cert, requires that "--p12cert" is set'
    echo '  --basic-auth USER:PASS          specify credentials for basic HTTP auth on communication with Configuration-Management'
    echo "  --node-ip IP                    specify MESH Node public IP address"
    echo "  --rabbit-host HOSTNAME          specify RabbitMQ hostname"
    echo "  --rabbit-port PORT              specify RabbitMQ port"
    echo "  --rabbit-user USER              specify RabbitMQ username"
    echo "  --rabbit-pass PASS              specify RabbitMQ password"
    echo "  --eureka-server DOMAIN          specify Eureka server domain (url or ip:port)"
    echo "  --registry-url URL              specify docker registry url"
    echo "  -u, --registry-user USER        specify docker registry username"
    echo "  -p, --registry-pass PASS        specify docker registry password"
    echo
    exit 0
}

assert_exists() {
    [ -n "${1}" ] || usage
}
check_operating_system() {
    OPERATING_SYSTEM=$(uname)
    VERSION=$(uname -r)
    echo "Operating system: ${OPERATING_SYSTEM}"
    echo "Version: ${VERSION}"

    if [ "${OPERATING_SYSTEM}" != "Darwin" ] && [ "${OPERATING_SYSTEM}" != "Linux" ]; then
        echo "Unsupported operating system detected!"
        echo "Supported operating systems:"
        echo " - Linux"
        echo " - Darwin (OSX)"
        exit 3
    fi
}
not_found() {
    echo "${1} not found"
    echo "Please install ${1} in order to start MESH Node"
    exit 4
}

check_docker_compose_version() {
    VERSION=$(docker-compose version --short)
    NUMBER=$(echo ${VERSION} | awk -F. '{print $2}')
    if [ ${NUMBER} -lt 19 ]; then
        echo "Unsupported version of docker-compose detected"
        echo "Please update docker-compose to version 1.19 or higher"
        exit 4
    fi
    echo "Docker-Compose: ${VERSION}"
}

check_required_software() {
    which curl 1> /dev/null || not_found curl
    which grep 1> /dev/null || not_found grep
    which awk 1> /dev/null || not_found awk
    which netstat 1> /dev/null || not_found netstat
    which ifconfig 1> /dev/null || not_found ifconfig
    which docker 1> /dev/null && echo "Docker: $(docker version --format='{{print .Client.Version}}')" || not_found docker
    which docker-compose 1> /dev/null && check_docker_compose_version || not_found docker-compose
}
check_user_permissions() {
    docker run --rm hello-world 1> /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "You don't have required permissions to run docker"
        echo "Add your user to the \"docker\" group with command like:"
        echo
        echo "  sudo usermod -aG docker $(whoami)"
        echo
        echo "or"
        echo
        echo "  su -c 'usermod -aG docker $(whoami)'"
        echo
        echo "Remember that you have to log out and back in for this to take effect."
        echo "Afterwards run this script again."
        exit 5
    fi
}
assign_empty_port() {
    PORT=${1}
    (netstat -tulpn | grep ${PORT}) 1> /dev/null 2>&1 && echo $(assign_empty_port $((PORT+1))) || echo ${PORT}
}
ask_for_value_or_default() {
    read -p "${1} [default: ${2}]: " TEMP </dev/tty
    echo ${TEMP:-${2}}
}

ask_for_secret() {
    stty -echo </dev/tty
    trap 'stty echo </dev/tty' EXIT
    read -p "${1} [use default]: " PASSWORD </dev/tty
    stty echo </dev/tty
    trap - EXIT
    echo ${PASSWORD:-${2}}
}

ask_for_services() {
    export SPRING_RABBITMQ_HOST=$(ask_for_value_or_default "RabbitMQ address" ${SPRING_RABBITMQ_HOST})
    export SPRING_RABBITMQ_PORT=$(ask_for_value_or_default "RabbitMQ port" ${SPRING_RABBITMQ_PORT})
    export SPRING_RABBITMQ_USERNAME=$(ask_for_value_or_default "RabbitMQ user" ${SPRING_RABBITMQ_USERNAME})
    export SPRING_RABBITMQ_PASSWORD=$(ask_for_secret "RabbitMQ password" ${SPRING_RABBITMQ_PASSWORD}) ; echo
    export EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=$(ask_for_value_or_default "Eureka server URL" ${EUREKA_CLIENT_SERVICEURL_DEFAULTZONE})
    export REGISTRY_URL=$(ask_for_value_or_default "Docker registry URL" ${REGISTRY_URL})
    export REGISTRY_USER=$(ask_for_value_or_default "${REGISTRY_URL} user" ${REGISTRY_USER})
    export REGISTRY_PASS=$(ask_for_secret "${REGISTRY_URL} password" ${REGISTRY_PASS}) ; echo
}

no_mesh_address_provided() {
    echo "No IP address provided!"
    exit 3
}

ask_for_node_address() {
    echo
    echo "IPv4 addresses available at your machine:"
    ifconfig | grep "inet " | cut -d't' -f 2 | cut -d' ' -f 2 | cut -d'/' -f 1 | cut -d':' -f 2 | grep -v 127.0.0.1
    echo "Please provide IPv4 address or hostname reachable by other nodes in your MESH network"
    echo "Note: It is possible to run MESH Node behind any reverse proxy solution (e.g haproxy, nginx etc.)"
    echo "In that case provide address of reverse proxy"
    read -p 'MESH Node address: ' SPRING_CLOUD_CLIENT_IPADDRESS </dev/tty
    [ -n "${SPRING_CLOUD_CLIENT_IPADDRESS}" ] || no_mesh_address_provided
    export SPRING_CLOUD_CLIENT_IPADDRESS=${SPRING_CLOUD_CLIENT_IPADDRESS}
}

obtain_configuration_parameters() {
    [ -n "${IP_PROVIDED}" ] && echo "MESH Node address: ${SPRING_CLOUD_CLIENT_IPADDRESS}" || ask_for_node_address
    [ -n "${INTERACTIVE}" ] && ask_for_services
}
login() {
    docker login --username ${REGISTRY_USER} --password ${REGISTRY_PASS} ${REGISTRY_URL}  1> /dev/null 2>&1
}

login_failed() {
    echo
    echo "Login to ${REGISTRY_URL} failed"
    echo "If this registry requires client certificates o authenticate, please place them in proper directory"
    echo "For Linux:"
    echo "  /etc/docker/certs.d/${REGISTRY_URL}"
    echo "For OSX:"
    echo "  /Users/${USER}/.docker/certs.d/${REGISTRY_URL}"
    echo ""
    echo "More information can be found here:"
    echo "  https://docs.docker.com/engine/security/certificates"
    exit 7
}

authorize_in_nexus() {
    if [ -z ${SKIP_AUTH} ]; then
        login && echo "Login to ${REGISTRY_URL} succeeded" || login_failed
    else
        echo "Skipping docker registry authentication"
    fi
}
assign_empty_ports() {
    export GATEWAY_PORT=$(assign_empty_port 9191)
    export IOTA_NODE_API_PORT=$(assign_empty_port 14265)
    export IOTA_NODE_UDP_PORT=$(assign_empty_port 14777)
    export IOTA_NODE_TCP_PORT=$(assign_empty_port 15777)


}




volume_exists() {
    docker volume inspect ${1} 1> /dev/null 2>&1
}

clean_volume() {
    docker-compose --file ${DOCKER_COMPOSE_FILE} down
    docker volume rm ${1}
    docker volume create --name=${1}
}

should_clean() {
    VOLUME=${1}
    echo "Docker volume ${VOLUME} already exists"
    if [ -n "${ASSUME_YES}" ]; then
        clean_volume ${VOLUME}
    elif [ -z ${ASSUME_NO} ]; then
        read -p 'Do you want to clean volume before starting MESH Node? [y/n] ' REMOVE </dev/tty
        if  [ "${REMOVE}" = "y" ] || [ "${REMOVE}" = "Y" ]; then
            clean_volume ${VOLUME}
        fi
    fi
}

create_networks_and_volumes() {
    docker network create trident-stax-1-iota 1> /dev/null 2>&1
    VOLUME=trident-stax-1-iota_node
    volume_exists ${VOLUME} && should_clean ${VOLUME} || docker volume create --name=${VOLUME}


}

remove_networks_and_volumes() {
    docker network rm trident-stax-1-iota
    docker volume rm trident-stax-1-iota_node


}
download_failed() {
    echo "${DOCKER_COMPOSE_FILE} download failed (${1})"
    exit 2
}

download_docker_compose() {
    if [ -n "${CA_CERT}" ]; then
        DOWNLOAD_COMMAND="curl -G --cacert ${CA_CERT} -s -w %{http_code} ${DOCKER_COMPOSE_URL} -o ${DOCKER_COMPOSE_FILE}"
    elif [ -n "${P12_CERT}" ] && [ -n "${P12_PASS}" ]; then
        DOWNLOAD_COMMAND="curl -G --cert-type P12 --cert ${P12_CERT} --pass ${P12_PASS} -s -w %{http_code} ${DOCKER_COMPOSE_URL} -o ${DOCKER_COMPOSE_FILE}"
    elif [ -n "${BASIC_AUTH}" ]; then
        DOWNLOAD_COMMAND="curl -G --user ${BASIC_AUTH} -s -w %{http_code} ${DOCKER_COMPOSE_URL} -o ${DOCKER_COMPOSE_FILE}"
    else
        DOWNLOAD_COMMAND="curl -G -s -w %{http_code} ${DOCKER_COMPOSE_URL} -o ${DOCKER_COMPOSE_FILE}"
    fi
    STATUS=$(eval ${DOWNLOAD_COMMAND})
    [ "${STATUS}" -eq "200" ] && echo "${DOCKER_COMPOSE_FILE} download succeeded" || download_failed ${STATUS}
}

is_already_started() {
    docker-compose --file ${DOCKER_COMPOSE_FILE} ps --services --filter "status=running"
}

install_succeeded() {
    echo "Installing MESH Node succeeded"
    echo
    echo "MESH Node Gateway port: ${GATEWAY_PORT}"
    echo "MESH Node is up and running"
    exit 0
}

install_failed() {
    echo "Installing MESH Node failed"
    exit 2
}

install_mesh_node () {
    check_operating_system
    check_required_software
    check_user_permissions
    obtain_configuration_parameters
    authorize_in_nexus
    download_docker_compose
    create_networks_and_volumes
    docker-compose --file ${DOCKER_COMPOSE_FILE} stop
    assign_empty_ports
    docker-compose --file ${DOCKER_COMPOSE_FILE} pull
    docker-compose --file ${DOCKER_COMPOSE_FILE} build

    docker-compose --file ${DOCKER_COMPOSE_FILE} up -d --no-build && install_succeeded || install_failed
}

start_mesh_node () {
    [ -n "$(is_already_started)" ] && echo "MESH Node is already up" || (assign_empty_ports ; docker-compose --file ${DOCKER_COMPOSE_FILE} start)
    exit 0
}

list_containers () {
    CONTAINERS=$(docker-compose --file ${DOCKER_COMPOSE_FILE} ps -q)
    if [ "${CONTAINERS}" ]; then
        for CONTAINER_ID in ${CONTAINERS}
        do
            docker inspect -f "{{.Name}}:   {{.State.Status}}" ${CONTAINER_ID} | cut -c 2-
        done
    else
        echo "No containers of MESH Node are running"
    fi
    exit 0
}

container_status () {
    CONTAINER_ID=${1}
    docker inspect -f "{{.State.Status}}" ${CONTAINER_ID} 2> /dev/null || (echo "Docker container not found" ; exit 1)
    exit
}

stop_mesh_node() {
    [ -n "$(is_already_started)" ] && docker-compose --file ${DOCKER_COMPOSE_FILE} stop || echo "MESH Node is already down"
    exit 0
}

remove_mesh_node() {
    docker-compose --file ${DOCKER_COMPOSE_FILE} down
    if [ -n "${ASSUME_YES}" ]; then
        remove_networks_and_volumes
    elif [ -z ${ASSUME_NO} ]; then
        read -p 'Do you want to remove docker volumes and networks? [y/n] ' REMOVE </dev/tty
        if  [ "${REMOVE}" = "y" ] || [ "${REMOVE}" = "Y" ]; then
            remove_networks_and_volumes
        fi
    fi
    echo "MESH Node has been removed"
    exit 0
}

main() {
    while [ ! $# -eq 0 ]
    do
        case "$1" in
            -h|--help)
            usage
            exit 0
            ;;
            -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
            -s|--skip-registry-auth)
            SKIP_AUTH=true
            shift
            ;;
            -y|--assume-yes)
            ASSUME_YES=true
            shift
            ;;
            -n|--assume-no)
            ASSUME_NO=true
            shift
            ;;
            install)
            FUNCTION=install_mesh_node
            shift
            ;;
            start)
            FUNCTION=start_mesh_node
            shift
            ;;
            stop)
            FUNCTION=stop_mesh_node
            shift
            ;;
            remove)
            FUNCTION=remove_mesh_node
            shift
            ;;
            ps)
            FUNCTION=list_containers
            shift
            ;;
            status)
            shift
            assert_exists ${1}
            FUNCTION="container_status ${1}"
            shift
            ;;
            --cacert)
            shift
            assert_exists ${1}
            CA_CERT=${1}
            shift
            ;;
            --p12cert)
            shift
            assert_exists ${1}
            P12_CERT=${1}
            shift
            ;;
            --p12pass)
            shift
            assert_exists ${1}
            P12_PASS=${1}
            shift
            ;;
            --basic-auth)
            shift
            assert_exists ${1}
            BASIC_AUTH=${1}
            shift
            ;;
            --node-ip)
            shift
            assert_exists ${1}
            IP_PROVIDED=true
            SPRING_CLOUD_CLIENT_IPADDRESS=${1}
            shift
            ;;
            --rabbit-host)
            shift
            assert_exists ${1}
            SPRING_RABBITMQ_HOST=${1}
            shift
            ;;
            --rabbit-port)
            shift
            assert_exists ${1}
            SPRING_RABBITMQ_PORT=${1}
            shift
            ;;
            --rabbit-user)
            shift
            assert_exists ${1}
            SPRING_RABBITMQ_USERNAME=${1}
            shift
            ;;
            --rabbit-pass)
            shift
            assert_exists ${1}
            SPRING_RABBITMQ_PASSWORD=${1}
            shift
            ;;
            --eureka-server)
            shift
            assert_exists ${1}
            EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=${1}
            shift
            ;;
            --registry-url)
            shift
            assert_exists ${1}
            REGISTRY_URL=${1}
            shift
            ;;
            -u|--registry-user)
            shift
            assert_exists ${1}
            REGISTRY_USER=${1}
            shift
            ;;
            -p|--registry-pass)
            shift
            assert_exists ${1}
            REGISTRY_PASS=${1}
            shift
            ;;
            *)
            usage
            exit 1
            ;;
        esac
    done
    get_default_values
    ${FUNCTION:-install_mesh_node}
    exit 0
}

main "$@"
