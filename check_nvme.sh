#!/bin/bash

nvme_cmd=${nvme_cmd-./nvme}

nvme_ver_str=`${nvme_cmd} --version | cut -d" " -f 3`
nvme_ver=(`echo ${nvme_ver_str} | sed "s/\./ /g"`)

msg="nvme version need to be 1.12 or newer. current version is ${nvme_ver_str}"

if [ ${#nvme_ver[@]} -lt 2 ]; then echo ${msg}; exit 1; fi

if [ ${nvme_ver[0]} -lt 1 ]; then echo ${msg}; exit 1; fi

if [ ${nvme_ver[1]} -lt 12 ]; then echo ${msg}; exit 1; fi

echo "nvme-cli version ${nvme_ver_str} has SR-IOV support"