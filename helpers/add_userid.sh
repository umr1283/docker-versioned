#!/bin/bash

add_userid() {
  USERNAME=$1
  ID=$2
  STATUS=$3

  if [ -d /media/user/$USERNAME ]
  then
    useradd \
    --no-create-home \
    --no-user-group \
    --gid staff \
    --uid $ID \
    --home /media/user/$USERNAME \
    --groups staff,root,sudo \
    $USERNAME &&
    echo "$USERNAME:$USERNAME" | chpasswd
  else
    useradd \
    --create-home \
    --no-user-group \
    --gid staff \
    --uid $ID \
    --home /media/user/$USERNAME \
    --groups staff,root,sudo \
    $USERNAME &&
    echo "$USERNAME:$USERNAME" | chpasswd
  fi

  return 0
}
