#!/bin/bash

rm -rf `ls | grep -v "combined.img.gz"`
ls *rootfs*.gz | xargs rm -fr

exit 0
