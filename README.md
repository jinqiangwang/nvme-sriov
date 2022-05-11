# nvme-sriov

This project is to provide a set of scripts for NVMe SR-IOS related test.

nvme-cli binary path is defined in sriov-helper. Please use version nvme version 1.12 and later
(avoid 1.14 please) for test.
```
export nvme_cmd=/usr/sbin/nvme
export nvme_vu=/usr/sbin/nvme.vu
```


1. cfg_vf_ns.sh can be used to create NS, configure VQ/VI for VF, bring VF online, attach 
   NS to VF, and make VF visible to system. This script will retrieve nvme drive capacity 
   from fied "tnvmcap" from "nvme id-ctrl" output, and create namespace based on the value 
   of "NSG" from "nvme id-ns-granularity" output.

   Usage:

       ./cfg_vf_ns.sh -d <nvme_dev_name> -n <ns_count>

   Example:

       ./cfg_vf_ns.sh -d nvme0 -n 8 # will create 8 namespaces, each size is "drive_cap / 8"

2. recfg_max_vf.sh is to change the max usable VF count. Vendor specific command is needed
   for setting this value. Please contact the auther to get VU nvme command. With less VF 
   count, more VQ/VI resources can be assigned to each, which might help in case of high 
   concurrent I/O workload.

   Usage:

       ./recfg_max_vf.sh  -d <nvme_dev_name> -n <vf_count>

   Example:
   
       ./recfg_max_vf.sh  -d nvme0 -n 16 # change the max VF count to 16, but not persisit 
                                         # this configuration. after power cycle max VF
                                         # count will be restore to the intial value.
