#!/bin/bash 

nvme_dev=$1
nvme_cmd=${nvme_cmd-./nvme}

if [ "${nvme_dev}" == "" ]
then
    echo -e "please provide nvme dev name. \nexample: $0 nvme0"
    exit
fi

total_vf_cnt=`cat /sys/class/nvme/${nvme_dev}/device/sriov_totalvfs`
max_res_cnt=$((132/(${total_vf_cnt}+1)))

for((i=1; i<=${total_vf_cnt};i++))
do
    ${nvme_cmd} virt-mgmt /dev/${nvme_dev} -c $i -a 7
    ${nvme_cmd} virt-mgmt /dev/${nvme_dev} -c $i -r 0 -n ${max_res_cnt} -a 8
    ${nvme_cmd} virt-mgmt /dev/${nvme_dev} -c $i -r 1 -n ${max_res_cnt} -a 8
    ${nvme_cmd} virt-mgmt /dev/${nvme_dev} -c $i -a 9
done