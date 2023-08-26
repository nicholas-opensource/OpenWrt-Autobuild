#!/bin/bash

rm -rf `ls | grep -v "squashfs"`
ls *rootfs.img.gz | xargs rm -fr
gzip -d *.gz
gzip *.img
for gzfirm in *.gz; do
  sha256sum "$gzfirm" >> sha256sum.txt
done
mv ../../../../.config config-full

exit 0
