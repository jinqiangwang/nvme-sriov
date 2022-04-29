#!/bin/bash 

nvme_dev=$1
nvme_cmd=${nvme_cmd-nvme}

if [ "${nvme_dev}" == "" ]
then
    echo -e "please provide nvme dev name. \nexample: $0 nvme0"
    exit
fi

ns_list=(`${nvme_cmd} list-ns /dev/${nvme_dev} -a | cut -d: -f2`)

if [ ${#ns_list[@]} -eq 0 ]
then
    echo "no ns detected"
    exit
else
    echo "${#ns_list[@]} ns(es) detected"
fi

for ns in ${ns_list[@]}
do
    ctrl=`${nvme_cmd} list-ctrl /dev/${nvme_dev} -n ${ns} | cut -d: -f 2`
    if [ "${ctrl}" != "" ]
    then
        ${nvme_cmd} detach-ns /dev/${nvme_dev} -c ${ctrl} -n ${ns}
    fi
done
