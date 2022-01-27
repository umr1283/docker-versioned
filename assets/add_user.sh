#!/bin/bash

USER=$1
ID=$2

if [ -d /home/$USER ]; then
  CH="--no-create-home"
else
  CH="--create-home"
fi

if [ -z "$3" ]; then
  USERGRP="staff"
else
  USERGRP="$3"
fi

if [ "$USERGRP" = "admin" ]; then
  GRPS="staff,root,sudo"
  echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
else
  GRPS="staff"
fi

useradd $CH --no-user-group --gid staff --uid $ID --groups $GRPS $USER

[ -f /home/$USER/.bash_aliases ] || echo '
# .bash_aliases
umask 0002
export PS1="________________________________________________________________________________\n| \w @ \H (\u) \n| > "
export PS2="| > "
alias ls="ls --color=auto"
alias ll="ls --color=auto -Flhp"
alias l="ls --color=auto -FlAhp"
cd() { builtin cd "$@"; ll; } 
alias cp="cp -iv"
alias mv="mv -iv"
alias rm="rm -iv"
alias mkdir="mkdir -pv"
' > /home/$USER/.bash_aliases && chown -R $USER:staff /home/$USER

# set key auth in file
if [ -n "$(pgrep sshd)" ]; then
  PUBLICKEY=$4

  if [ ! -d /home/$USER/.ssh ]; then
    mkdir /home/$USER/.ssh
  fi

  [ -f /home/$USER/.ssh/authorized_keys ] || touch /home/$USER/.ssh/authorized_keys

  [[ -n "$PUBLICKEY" ]] && \
    [[ ! $(grep "$PUBLICKEY" /home/$USER/.ssh/authorized_keys) ]] && \
    echo "$PUBLICKEY" >> /home/$USER/.ssh/authorized_keys

  chown -R $USER:staff /home/$USER/.ssh && \
    chmod 700 /home/$USER/.ssh && \
    chmod 600 /home/$USER/.ssh/authorized_keys
fi

if [[ 
  ( 
    (-n "$(pgrep sshd)") || (-n "$(pgrep rserver)")
  ) && 
  ( 
    (! -s ~/.ssh/authorized_keys) || ("$USERGRP" = "admin")
  ) && 
  (
    (-n "$(grep -E '[# \t]*PasswordAuthentication yes' /etc/ssh/ssh_config)") ||
    (-n "$(grep -E '[# \t]*PasswordAuthentication yes' /etc/ssh/sshd_config)")
  )
]]; then
  echo "$USER:$USER" | chpasswd
else 
  echo "$USER:$(openssl rand -base64 14)" | chpasswd
fi

echo "Changing S6 container_environment permissions!"

## Set our dynamic variables in Renviron.site to be reflected by RStudio Server or Shiny Server
exclude_vars="HOME PASSWORD RSTUDIO_VERSION"
for file in /var/run/s6/container_environment/*
do
  sed -i "/^${file##*/}=/d" ${R_HOME}/etc/Renviron.site
  regex="(^| )${file##*/}($| )"
  [[ ! $exclude_vars =~ $regex ]] && echo "${file##*/}=$(cat $file)" >> ${R_HOME}/etc/Renviron.site || echo "skipping $file"
done

## only file-owner (root) should read container_environment files:
chmod 600 /var/run/s6/container_environment/*

echo "User $USER created!"
