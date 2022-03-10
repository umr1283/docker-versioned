#!/bin/bash

function deploy_container() {
  if [ -z "$1" ]; then
    echo "Error 1: Missing Docker image name, e.g., \"rstudio\"!"
    return 1
  else
    local IMG=$1
  fi

  if [ -z "$2" ]; then
    echo "Error 2: Missing Docker image version, e.g., \"4.1.2\"!"
    return 2
  else
    local VERSION=$2
  fi

  local NAME="${IMG}-v${VERSION}"

  echo "Starting Docker container ${IMG}-server \"${NAME}\" ..."

  local TMP=/media/datatmp/dockertmp

  local TMPRENV=$TMP/renv_pkgs_cache
  if [ ! -e $TMPRENV ]; then
    mkdir -p -m 775 $TMPRENV ;
  fi

  if [ -z "$3" ]; then
    echo "Docker container ${IMG}-server \"${NAME}\" will have access to all projects!"

    if [[ (-n "$(docker ps | grep -E '^${NAME}$')") ]]; then
      echo "Error 3: A container with the same name is already running!"
      return 3
    fi

    local TMPDIR=$TMP/$HOSTNAME--$NAME
    if [ -e $TMPDIR ]; then
      rm -rf $TMPDIR
    fi
    mkdir -p -m 775 $TMPDIR
    chgrp staff $TMPDIR

    if [ "${IMG%-*}" = "shiny" ]; then
      local DOCKER_NAME="--name ${NAME} --hostname ${NAME}"
    else
      if [ -n "$SUDO_USER" ]; then
        local USER_NAME=$SUDO_USER
      else
        local USER_NAME=$(whoami)
      fi
      local DOCKER_NAME="--name ${NAME}--${USER_NAME} --hostname ${NAME}"
    fi
    local DOCKER_DEFAULT="--detach --env \"RENV_PATHS_CACHE=/renv_cache\""
    local DOCKER_VOLUMES="--volume ${TMPRENV}:/renv_cache \
      --volume /media:/media \
      --volume /media:/Isiprod1 \
      --volume /media/archive:/disks/ARCHIVE \
      --volume /media/run:/disks/RUN \
      --volume /media/data:/disks/DATA \
      --volume /media/project:/disks/PROJECT \
      --volume /media/datatmp:/disks/DATATMP"

    case ${IMG%-*} in
      "ssh") local PORT="22${VERSION//.}:2222";;
      "rstudio") local PORT="8${VERSION//.}:8787";;
      "shiny") if [ "${IMG##*-}" = "stable" ]; then PORT="3838:3838"; else PORT="38${VERSION//.}:3838"; fi;;
    esac

    if [ "${IMG%-*}" = "shiny" ]; then
      local DOCKER_VOLUMES="${DOCKER_VOLUMES} \
        --volume /media/project/Rshiny/${IMG##*-}:/srv/shiny-server \
        --volume /media/project/Rshiny-logs/${IMG##*-}:/var/log/shiny-server"
    else
      local DOCKER_VOLUMES="${DOCKER_VOLUMES} \
        --volume /media/user:/home --volume ${TMPDIR}:/tmp"
    fi

    docker run \
      ${DOCKER_NAME} \
      ${DOCKER_DEFAULT} \
      ${DOCKER_VOLUMES} \
      --publish ${PORT} \
      umr1283/${IMG%-*}:${VERSION}

    if [ "${IMG%-*}" = "shiny" ]; then
      docker exec ${NAME} /bin/bash -c "usermod -a -G staff shiny && usermod -g staff shiny"
    fi
  else
    PROJECT=$3
    echo "Docker container ${IMG}-server \"${NAME}\" will only have access to \"${PROJECT}\"!"

    if [[ (-n "$(docker ps | grep -E '^${NAME}--${PROJECT}$')") ]]; then
      echo "Error 3: A container with the same name is already running!"
      return 3
    fi
    
    local TMPDIR=$TMP/$HOSTNAME--$NAME--$PROJECT
    if [ -e $TMPDIR ]; then
      rm -rf $TMPDIR
    fi
    mkdir -p -m 775 $TMPDIR
    chgrp staff $TMPDIR

    local DOCKER_NAME="--name ${NAME}--${PROJECT} --hostname ${NAME}--${PROJECT}"
    
    local DOCKER_DEFAULT="--detach --env \"RENV_PATHS_CACHE=/renv_cache\""
    local DOCKER_VOLUMES="--volume /media/user:/home \
      --volume ${TMPDIR}:/tmp\
      --volume ${TMPRENV}:/renv_cache \
      --volume /media/project/${PROJECT}:/disks/PROJECT/${PROJECT} \
      --volume /media/datatmp/${PROJECT}:/disks/DATATMP/${PROJECT}"

    case ${IMG} in
      "ssh") local PORT="23${VERSION//.}:2222";;
      "rstudio") local PORT="9${VERSION//.}:8787";;
    esac

    docker run \
      ${DOCKER_NAME} \
      --cpus 40 \
      --memory 256g \
      ${DOCKER_DEFAULT} \
      ${DOCKER_VOLUMES} \
      --publish ${PORT} \
      umr1283/${IMG}:${VERSION}
  fi

  echo "Docker container ${IMG}-server \"${NAME}\" online!"

  return 0
}
