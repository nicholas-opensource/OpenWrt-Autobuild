#!/bin/bash
rm -rf `ls | grep -v "squashfs"`
gzip -d *.gz
gzip *.img
mv ../../../../.config config-full

exit 0
