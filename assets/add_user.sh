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

[ -f /home/$USER/.bash_profile ] || echo '
# .bash_profile

# cat /dev/null > ~/.bash_history && history -c

# umask u=rwx,g=rwx,o=
umask 0002
export LANG="en_GB.UTF-8"
export LANGUAGE="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"
# export LC_CTYPE="en_GB.UTF-8"
# export LC_NUMERIC="en_GB.UTF-8"
# export LC_TIME="en_GB.UTF-8"
# export LC_COLLATE="en_GB.UTF-8"
# export LC_MONETARY="en_GB.UTF-8"
# export LC_MESSAGES="en_GB.UTF-8"
# export LC_PAPER="en_GB.UTF-8"
# export LC_NAME="en_GB.UTF-8"
# export LC_ADDRESS="en_GB.UTF-8"
# export LC_TELEPHONE="en_GB.UTF-8"
# export LC_MEASUREMENT="en_GB.UTF-8"
# export LC_IDENTIFICATION="en_GB.UTF-8"
export PS1="________________________________________________________________________________\n| \w @ \H (\u) \n| > "
export PS2="| > "
export BLOCKSIZE=1k
export SHELL
export LS_OPTIONS="--color=auto"
eval "`dircolors`"
alias ls="ls $LS_OPTIONS"
alias ll="ls $LS_OPTIONS -Flhp"
alias l="ls $LS_OPTIONS -FlAhp"
cd() { builtin cd "$@"; ll; } 
alias cp="cp -iv"
alias mv="mv -iv"
alias rm="rm -iv"
alias mkdir="mkdir -pv"
' > /home/$USER/.bash_profile && chown -R $USER:staff /home/$USER

# set key auth in file
if [ -n "$(pgrep sshd)" ]; then
  if [ "$USERGRP" = "admin" ]; then
    echo "$USER:$USER" | chpasswd
  else
    # echo "$USER:$(openssl rand -base64 14)" | chpasswd
    echo "$USER:$USER" | chpasswd
  fi
  
  PUBLICKEY=$4

  [ -f /home/$USER/.ssh/authorized_keys ] || touch /home/$USER/.ssh/authorized_keys

  [[ -n "$PUBLICKEY" ]] && \
    [[ ! $(grep "$PUBLICKEY" /home/$USER/.ssh/authorized_keys) ]] && \
    echo "$PUBLICKEY" >> /home/$USER/.ssh/authorized_keys

  chown -R $USER:staff /home/$USER/.ssh && \
    chmod 700  /home/$USER/.ssh && \
    chmod 600  /home/$USER/.ssh/authorized_keys
else 
  if [ -n "$(pgrep rserver)" ]; then
    echo "$USER:$USER" | chpasswd
  fi
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
