#!/bin/bash 

export nvme_cmd=./nvme

ns_cnt=
nvme_dev=
example_str="example:\n\t $0 -d nvme0 -n 4\n"
nvme_cmd=${nvme_cmd-./nvme}

while getopts "n:d:" opt
do
    case $opt in 
    n)
        ns_cnt=$OPTARG
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

./check_nvme.sh
if [ $? -ne 0 ]; then exit 1; fi

drive_cap=$((`${nvme_cmd} id-ctrl /dev/${nvme_dev} | grep tnvmcap | cut -d: -f2`/1000/1000/1000))
total_vf_cnt=`cat /sys/class/nvme/${nvme_dev}/device/sriov_totalvfs 2>/dev/null`

echo "dev: ${nvme_dev}; capacity: ${drive_cap}; max_vf_cnt: ${total_vf_cnt}"

if [ -z ${total_vf_cnt} ]
then
    echo "please check if sr-iov is supported on ${nvme_dev}"
    exit
fi

if [[ -z "${ns_cnt}" ]] || [[ $((${ns_cnt})) -le 0 ]] || [[ ${ns_cnt} -gt ${total_vf_cnt} ]]
then
    echo -e "incorrect ns count, ns need to be in [1, 32]. \n${example_str}"
    exit
fi

active_vf_cnt=${ns_cnt}
max_res_cnt=$((132/(${total_vf_cnt}+1)))
ns_base_cap=$((${drive_cap}*1000*1000*1000/512/${total_vf_cnt}))

# detach all NS
./detach-ns.sh ${nvme_dev}

# delete all NS
./delete-ns.sh ${nvme_dev}

# disable all VF
echo 0 > /sys/class/nvme/${nvme_dev}/device/sriov_numvfs

# offline all VF in online status
./offline-vf.sh ${nvme_dev}

# create NS
./create-ns.sh -d ${nvme_dev} -n ${ns_cnt}

# assign resouse to VFs and bring them online
./config-vf.sh ${nvme_dev}

# attach NS to VF
./attach-ns.sh ${nvme_dev}

echo ${ns_cnt} > /sys/class/nvme/${nvme_dev}/device/sriov_numvfs


echo 'waiting for 5 seconds ...'
sleep 5

ts=`date +%Y%m%d_%H%M%S`
echo -e "${ts}\n" >> smart_${nvme_dev}.log
${nvme_cmd} smart-log /dev/${nvme_dev} >> smart_${nvme_dev}.log
echo -e "\n\n" >> smart_${nvme_dev}.log
${nvme_cmd} list | grep -e ${nvme_dev} -e Node -e \-\- | sort -V