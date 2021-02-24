#!/bin/bash

rm -rf `ls | grep -v "squashfs"`
ls *rootfs.img.gz | xargs rm -fr
gzip -d *.gz
gzip *.img
mv ../../../../.config config-full

exit 0
