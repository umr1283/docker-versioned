#!/bin/sh

# start rstudio server
echo "rstudio server is starting"
rstudio-server start

# Infinite loop for container never stop when not shiny
tail -f /dev/null
