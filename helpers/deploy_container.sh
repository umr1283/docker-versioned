#!/bin/bash

function deploy_container() {
  DIRMOUNT=/media # or /Isiprod1

  if [ -z "$1" ]; then
    echo "Error 1: Missing Docker image name, i.e., \"r-ver\", \"umr1283\", \"rstudio\", \"ssh\", or \"shiny\"!"
    return 1
  else
    local IMG=$1
  fi

  if [ -z "$2" ]; then
    echo "Error 2: Missing Docker image version, e.g., \"4.1.2\" or \"devel\"!"
    return 2
  else
    local VERSION=$2
  fi

  if [ "${VERSION}" = "devel" ]; then
    local NAME="${IMG}-${VERSION}"
    local BASEDOCKERHUB="mcanouil"
  else
    local NAME="${IMG}-v${VERSION}"
    local BASEDOCKERHUB="umr1283"
  fi

  local TMP=${DIRMOUNT}/datatmp/dockertmp

  local TMPRENV=${TMP}/renv_pkgs_cache
  if [ ! -e ${TMPRENV} ]; then
    mkdir -p -m 775 ${TMPRENV}
  fi

  if [ -z "$3" ]; then
    if [ "${IMG%-*}" = "shiny" ]; then
      local DOCKER_NAME="--name ${NAME} --hostname ${NAME}"
      local TMPDIR=${TMP}/${HOSTNAME}--${NAME}
    else
      if [ -n "${SUDO_USER}" ]; then
        local USER_NAME=${SUDO_USER}
      else
        local USER_NAME=$(whoami)
      fi
      local DOCKER_NAME="--name ${NAME}--${USER_NAME} --hostname ${NAME}"
      local TMPDIR=${TMP}/${HOSTNAME}--${NAME}--${USER_NAME}
      if [ -e ${TMPDIR} ]; then
        rm -rf ${TMPDIR}
      fi
      mkdir -p -m 775 ${TMPDIR}
      chgrp staff ${TMPDIR}
    fi

    echo "Starting Docker container ${IMG}-server \"${NAME}--${USER_NAME}\" ..."
    echo "Docker container ${IMG}-server \"${NAME}--${USER_NAME}\" will have access to all projects!"

    if [[ (-n "$(docker ps | grep -E '^${NAME}--${USER_NAME}$')") ]]; then
      echo "Error 3: A container with the same name is already running!"
      return 3
    fi

    local DOCKER_DEFAULT="--detach --env \"RENV_PATHS_CACHE=/renv_cache\""
    local DOCKER_VOLUMES="--volume ${TMPRENV}:/renv_cache \
      --volume ${DIRMOUNT}:/media \
      --volume ${DIRMOUNT}:/Isiprod1 \
      --volume ${DIRMOUNT}/archive:/disks/ARCHIVE \
      --volume ${DIRMOUNT}/run:/disks/RUN \
      --volume ${DIRMOUNT}/data:/disks/DATA \
      --volume ${DIRMOUNT}/project:/disks/PROJECT \
      --volume ${DIRMOUNT}/datatmp:/disks/DATATMP"

    if [ "${VERSION}" = "devel" ]; then
      case ${IMG%-*} in
      "ssh") local PORT="22999:2222" ;;
      "rstudio") local PORT="8999:8787" ;;
      "shiny") local PORT="38999:3838" ;;
      esac
    else
      case ${IMG%-*} in
      "ssh") local PORT="22${VERSION//./}:2222" ;;
      "rstudio") local PORT="8${VERSION//./}:8787" ;;
      "shiny") if [ "${IMG##*-}" = "stable" ]; then local PORT="3838:3838"; else local PORT="38${VERSION//./}:3838"; fi ;;
      esac
    fi

    if [ "${IMG%-*}" = "shiny" ]; then
      local DOCKER_VOLUMES="${DOCKER_VOLUMES} \
        --volume ${DIRMOUNT}/project/Rshiny/${IMG##*-}:/srv/shiny-server \
        --volume ${DIRMOUNT}/project/Rshiny-logs/${IMG##*-}:/var/log/shiny-server"
    else
      local DOCKER_VOLUMES="${DOCKER_VOLUMES} \
        --volume ${DIRMOUNT}/user:/home --volume ${TMPDIR}:/tmp"
    fi

    docker run \
      ${DOCKER_NAME} \
      ${DOCKER_DEFAULT} \
      ${DOCKER_VOLUMES} \
      --publish ${PORT} \
      ${BASEDOCKERHUB}/${IMG%-*}:${VERSION}

    if [ "${IMG%-*}" = "shiny" ]; then
      docker exec ${NAME} /bin/bash -c "usermod -a -G staff shiny && usermod -g staff shiny"
    fi

    echo "Docker container ${IMG}-server \"${NAME}--${USER_NAME}\" online!"
  else
    PROJECT=$3
    echo "Docker container ${IMG}-server \"${NAME}--${PROJECT}\" will only have access to \"${PROJECT}\"!"

    if [[ (-n "$(docker ps | grep -E '^${NAME}--${PROJECT}$')") ]]; then
      echo "Error 3: A container with the same name is already running!"
      return 3
    fi

    if [ "${VERSION}" = "devel" ]; then
      echo "Error 4: \"devel\" is not a valid version for \"${IMG}\" with limited access!"
      return 4
    fi

    local TMPDIR=${TMP}/${HOSTNAME}--${NAME}--${PROJECT}
    if [ -e ${TMPDIR} ]; then
      rm -rf ${TMPDIR}
    fi
    mkdir -p -m 775 ${TMPDIR}
    chgrp staff ${TMPDIR}

    local DOCKER_NAME="--name ${NAME}--${PROJECT} --hostname ${NAME}--${PROJECT}"

    local DOCKER_DEFAULT="--detach --env \"RENV_PATHS_CACHE=/renv_cache\""
    local DOCKER_VOLUMES="--volume ${DIRMOUNT}/user:/home \
      --volume ${TMPDIR}:/tmp\
      --volume ${TMPRENV}:/renv_cache \
      --volume ${DIRMOUNT}/project/${PROJECT}:/disks/PROJECT/${PROJECT} \
      --volume ${DIRMOUNT}/datatmp/${PROJECT}:/disks/DATATMP/${PROJECT}"

    case ${IMG} in
    "ssh") local PORT="23${VERSION//./}:2222" ;;
    "rstudio") local PORT="9${VERSION//./}:8787" ;;
    esac

    docker run \
      ${DOCKER_NAME} \
      --cpus 40 \
      --memory 256g \
      ${DOCKER_DEFAULT} \
      ${DOCKER_VOLUMES} \
      --publish ${PORT} \
      ${BASEDOCKERHUB}/${IMG}:${VERSION}

    echo "Docker container ${IMG}-server \"${NAME}--${PROJECT}\" online!"
  fi

  return 0
}
