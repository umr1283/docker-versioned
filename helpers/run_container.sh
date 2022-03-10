#!/bin/bash

function run_container() {
  if [ -z "$1" ]; then
    echo "Error 1: Missing project directory name!"
    return 1
  fi

  if [ -z "$2" ]; then
    echo "Error 2: Missing script name!"
    return 2
  fi

  if [ -z "$3" ]; then
    echo "Error 3: Missing IMAGE!"
    return 3
  else
    local IMAGE=$3
  fi

  local PROJECT=$1
  local SCRIPT=$2
  local SCRIPTCLEAN=${SCRIPT//\//-}

  if [[ (-n "$(docker ps | grep -E '${PROJECT}--${SCRIPTCLEAN}$')") ]]; then
    echo "Error 4: A container with the same name is already running!"
    return 4
  fi

  local LOG=${SCRIPTCLEAN%.*}
  local ROOTPROJECT=/disks/PROJECT/${PROJECT}

  local TMP=/media/datatmp/dockertmp

  local TMPDIR=$TMP/$HOSTNAME--${PROJECT}--${SCRIPTCLEAN}
  if [ -e $TMPDIR ]; then
    rm -rf $TMPDIR
  fi
  mkdir -p -m 775 $TMPDIR
  chgrp staff $TMPDIR

  local TMPRENV=$TMP/renv_pkgs_cache
  if [ ! -e $TMPRENV ]; then
    mkdir -p -m 775 $TMPRENV ;
  fi

  if [ -n "$SUDO_USER" ]; then
    local USER_NAME=$SUDO_USER
  else
    local USER_NAME=$(whoami)
  fi

  docker run \
    --name "${USER_NAME}--${PROJECT}--${SCRIPTCLEAN}" \
    --detach \
    --rm \
    --volume $TMPDIR:/tmp \
    --volume $TMPRENV:/renv_cache \
    --env "RENV_PATHS_CACHE=/renv_cache" \
    --volume /media:/media \
    --volume /media/archive:/disks/ARCHIVE \
    --volume /media/run:/disks/RUN \
    --volume /media/data:/disks/DATA \
    --volume /media/project:/disks/PROJECT \
    --volume /media/datatmp:/disks/DATATMP \
    ${IMAGE} /bin/bash -c "cd ${ROOTPROJECT}; Rscript scripts/${SCRIPT} >& logs/${LOG}.log"

  echo "Docker container \"${PROJECT}--${SCRIPTCLEAN}\" online!"

  return 0
}
