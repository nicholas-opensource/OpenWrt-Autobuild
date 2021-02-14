#!/bin/bash
rm -rf `ls | grep -v "squashfs"`
gzip -d *.gz
gzip *.img
mv ../../../../.config config-full
ls *rootfs*.gz | xargs rm -fr

exit 0
