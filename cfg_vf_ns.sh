#!/bin/bash 

ns_cnt=
export nvme_dev=
example_str="example:\n\t $0 -d nvme0 -n 4\n"
nvme_cmd=${nvme_cmd-./nvme}

while getopts "n:d:" opt
do
    case $opt in 
    n)
        ns_cnt=$OPTARG
        ;;
    d)
        export nvme_dev=$OPTARG
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

# check_nvme_cli ${nvme_cmd}
# if [ $? -ne 0 ]; then exit 1; fi

if [ -z ${hw_max_vf_cnt} ]
then
    echo "please check if sr-iov is supported on ${nvme_dev}"
    exit
fi

echo "dev: ${nvme_dev}; capacity: ${drive_cap}; hw_max_vf_cnt: ${hw_max_vf_cnt}; max_vf_cnt: ${max_vf_cnt}"

if [[ -z "${ns_cnt}" ]] || [[ $((${ns_cnt})) -lt 0 ]] || [[ ${ns_cnt} -gt ${max_vf_cnt} ]]
then
    echo -e "incorrect ns count, ns need to be in [0, 32]. \n${example_str}"
    exit
fi

# detach all NS
detach_all_ns ${nvme_dev}

# delete all NS
delete_all_ns ${nvme_dev}

# disable all VF
switch_vf ${nvme_dev} 0

# offline all VF in online status
offline_all_vf ${nvme_dev}

# create NS
create_all_ns ${nvme_dev} ${ns_cnt}

# assign resouse to VFs and bring them online
config_all_vf ${nvme_dev} ${ns_cnt}

# attach NS to VF
attach_all_ns ${nvme_dev}

# enable all VFs
switch_vf ${nvme_dev} ${ns_cnt}
