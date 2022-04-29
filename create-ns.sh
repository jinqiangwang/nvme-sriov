#!/bin/bash 

ns_cnt=
nvme_dev=
nvme_cmd=${nvme_cmd-./nvme}
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

if [ "${nvme_dev}" == "" ]
then
    echo -e "please provide nvme dev name. \nexample: $0 nvme0 4"
    exit
fi

if [ "${ns_cnt}" == "" ]
then
    echo -e "please provide ns cnt. \nexample: $0 nvme0 4"
    exit
fi

drive_cap=$((`${nvme_cmd} id-ctrl /dev/${nvme_dev} | grep tnvmcap | cut -d: -f2`/1000/1000/1000))
total_vf_cnt=`cat /sys/class/nvme/${nvme_dev}/device/sriov_totalvfs`
ns_granularity=$((`${nvme_cmd} id-ns-granularity /dev/${nvme_dev} | grep NSG | cut -d: -f 3`/512))
ns_base_cap=$((${drive_cap}*1000*1000*1000/512/${ns_granularity}*${ns_granularity}/${ns_cnt}))

echo "drive cap: ${drive_cap}; ns_granularity: ${ns_granularity}; ns_base_cap: ${ns_base_cap}"

for((i=0;i<${ns_cnt};i++))
do
    echo "${nvme_cmd} create-ns /dev/${nvme_dev} -s ${ns_base_cap} -c ${ns_base_cap} -f 0"
    ${nvme_cmd} create-ns /dev/${nvme_dev} -s ${ns_base_cap} -c ${ns_base_cap} -f 0
    # the last NS creation may fail, due to insufficient space
    # query remaining space using id-ctrl and try again
    if [ $? -ne 0 ] 
    then
        ns_cap=$((`${nvme_cmd} id-ctrl /dev/${nvme_dev} -H | grep unvmcap | cut -d: -f2`/512))
        ${nvme_cmd} create-ns /dev/${nvme_dev} -s ${ns_cap} -c ${ns_cap} -f 0
    fi 
done

