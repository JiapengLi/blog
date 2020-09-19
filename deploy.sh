#!/bin/bash
DATE=`date "+%F %T"`
git add .
git commit -m "update log $DATE"
git push origin master
