#!/bin/bash 

new_vf_cnt=
nvme_dev=
example_str="example:\n\t $0 -d nvme0 -n 4\n"
nvme_cmd=${nvme_cmd-./nvme}

while getopts "n:d:" opt
do
    case $opt in 
    n)
        new_vf_cnt=$OPTARG
        ;;
    d)
        nvme_dev=$OPTARG
        ;;
    *)
        echo -e ${example_str}
        exit
    esac
done

if [[ -z "${nvme_dev}" ]] || [[ `ls /dev/${nvme_dev} > /dev/null 2>&1; echo $?` -ne 0 ]]
then
    echo -e "incorrect nvme dev name, please check dev name. \n${example_str}"
    exit
fi

source sriov-helper 

echo "dev: ${nvme_dev}; drive_cap_gb: ${drive_cap_gb}; hw_max_vf_cnt: ${hw_max_vf_cnt}; max_vf_cnt: ${max_vf_cnt}"

if [ -z ${hw_max_vf_cnt} ]
then
    echo "please check if sr-iov is supported on ${nvme_dev}"
    exit
fi

if [[ -z "${new_vf_cnt}" ]] || [[ $((${new_vf_cnt})) -le 0 ]] || [[ ${new_vf_cnt} -gt ${hw_max_vf_cnt} ]]
then
    echo -e "incorrect ns count, ns need to be in [1, ${hw_max_vf_cnt}]. \n${example_str}"
    exit
fi

detach_all_ns ${nvme_dev}
delete_all_ns ${nvme_dev}
offline_all_vf ${nvme_dev}

# disable all VF
switch_vf ${nvme_dev} 0

${nvme_vu} dapu set-sriov /dev/${nvme_dev} -n ${new_vf_cnt}

# try power down / up
# slot=$(grep `cat /sys/class/nvme/${nvme_dev}/address | cut -d\. -f 1` /sys/bus/pci/slots/*/address | cut -d/ -f 1-6)
# echo 0 > ${slot}/power
# sleep 5
# echo 1 > ${slot}/power

# try to remove / rescan the pcie device
pcie_dev=$(find /sys/devices/pci* -name `cat /sys/class/nvme/${nvme_dev}/address` | grep -v iommu)
parent_dev=${pcie_dev%/*}
echo 1 > ${pcie_dev}/remove
echo 1 > ${parent_dev}/rescan

sleep 5
${nvme_cmd} list-secondary /dev/${nvme_dev}