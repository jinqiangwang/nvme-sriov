#!/bin/bash 

nvme_dev=$1
nvme_cmd=${nvme_cmd-./nvme}

if [ "${nvme_dev}" == "" ]
then
    echo -e "please provide nvme dev name. \nexample: $0 nvme0"
    exit
fi

# # offline those online VFs 
online_ctrls=($(${nvme_cmd} list-secondary /dev/${nvme_dev} | grep Online -B 2 | grep "Secondary Controller Identifier" | cut -d: -f 3))
for ctrl in ${online_ctrls[@]} 
do
    ${nvme_cmd} virt-mgmt /dev/${nvme_dev} -c ${ctrl} -a 7
done
