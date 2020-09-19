#!/bin/bash
DATE=`date "+%F %T"`
git add .
git commit -m "$DATE, update log "
git push origin master
