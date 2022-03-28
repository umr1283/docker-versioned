#!/bin/bash

function add_userid() {
  DIRMOUNT=/media # or /Isiprod1

  USERNAME=$1
  ID=$2
  STATUS=$3

  if [ -d ${DIRMOUNT}/user/$USERNAME ]; then
    useradd \
      --no-create-home \
      --no-user-group \
      --gid staff \
      --uid $ID \
      --home ${DIRMOUNT}/user/$USERNAME \
      --groups staff,root,sudo \
      --shell /bin/bash \
      $USERNAME &&
      echo "$USERNAME:$USERNAME" | chpasswd
  else
    useradd \
      --create-home \
      --no-user-group \
      --gid staff \
      --uid $ID \
      --home ${DIRMOUNT}/user/$USERNAME \
      --groups staff,root,sudo \
      --shell /bin/bash \
      $USERNAME &&
      echo "$USERNAME:$USERNAME" | chpasswd
  fi

  return 0
}
