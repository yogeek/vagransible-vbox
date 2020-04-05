#!/bin/bash

set -e

command -v vagrant >/dev/null 2>&1 || { echo >&2 "I require vagrant but it's not installed.  Aborting."; exit 1; }

if [[ "$(curl -m 15 -L -s -o /dev/null -I -w '%{http_code}' http://www.google.fr)" != "200" ]]
then
    echo "Internet connection : KO ! Please check your internet connection and try again." 
    echo "Warning : you must have a DIRECT connection to internet"
    exit 1
fi

# Launch vagrant build without GUI (headless mode for provisioning)
GUI=false vagrant up --provision # 2>&1 | tee provision.log

# Install Guest Addition  manually
# cf. https://github.com/marvel-nccr/quantum-mobile/issues/60#issuecomment-382083508
echo ""
echo "Guest Additions installation..."
vagrant vbguest --do install > vbguest.log
echo "Guest Additions installed !"
echo ""

# Add user to vboxsf group to avoid shared folder permission problem
# The user id must be 1002 (vagrant=1000, ubuntu=1001)
echo ""
echo "Set up permission for shared folder access..."
vagrant ssh -c 'sudo usermod -aG vboxsf $(getent passwd "1002" | cut -d: -f1)' &> /dev/null
echo ""

# Restart VM (GUI is enabled by default)
echo "Restart VM..."
vagrant reload
echo ""

# Get machine name from user config file to print some details about the VM
vm_name=$(grep "vm:" -A 1 .vagrantuser | grep "name:" | cut -d':' -f2 | xargs)
if [[ "$(grep "$vm_name" <(VBoxManage list runningvms))" != "" ]]
then
    vm_cfgfile=$(VBoxManage showvminfo "$vm_name" --machinereadable | grep -E 'CfgFile' | cut -d'=' -f2 | xargs dirname)
    vm_memory=$(VBoxManage showvminfo "$vm_name" --machinereadable | grep -E 'memory' | cut -d'=' -f2)
    vm_sharedfolder=$(VBoxManage showvminfo "$vm_name" --machinereadable | grep -E 'SharedFolderPathMachineMapping1' | cut -d'=' -f2 | cut -d'?' -f2)
else
    echo "Coult not find a running machine named $vm_name... Check if the VM has been created in VirtualBox and start it manually."
fi

cat << EOF

VM ready :-)

-----------------------------------------------------------------
Config info (you can change these parameters later in VirtualBox)
-----------------------------------------------------------------
VM location   : $vm_cfgfile
Shared Folder : $vm_sharedfolder ====> /sharedfolder
VM memory     : $vm_memory

EOF