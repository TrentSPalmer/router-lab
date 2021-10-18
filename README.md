# How To Use
## Blog Series
My [Six Part Blog Series](https://blog.trentsonlinedocs.xyz/posts/ansible-kvm-router-lab-part-1/)
provides a more exhaustive explaination of this project.
## Render This README in terminal
```bash
apt install python3-rich
# with pager
python3 -m rich.markdown README.md -p
# or without pager
python3 -m rich.markdown README.md
```

## Clone Template Machine
Build up a base template machine for Debian 11 Server.
We will call it *dnet*.
### Control Node
```bash
virt-clone --original dnet --name dcon --auto-clone
```
The control machine will be for controlling everything.

It needs to have root
ssh access to the base template machine (and then by extension all the clones),
in order to configure the *host names*, *host ssh keys*, and reset the
*machine-id*s.

Ansible does not need root ssh access.

## Name Resolution in libvirt networks
* Install libnss-libvirt
    * `apt install libnss-libvirt`
* configure `/etc/nsswitch.conf`
```cfg
# /etc/nsswitch.conf
...
hosts:          files libvirt dns mymachines
...
```

## Bash Scripts
### Set Up
1. build the virtual machines:
    * `sudo bash build_vms.bash`
2. confirm that machines are running:
    * `virsh list --state-running`
2. bring up the bridge networks:
    * `bash define_bridge_networks.bash`
    * `virsh net-list`
3. shutdown the vms so you can connect them to the bridges:
    * `bash shutdown_vms.bash`
    * `virsh list --state-running`
4. connect the vms to the bridges:
    * `bash connect_vms_to_bridges.bash`
    * `virsh domiflist dnetone`
    * `virsh domiflist dnettwo`
    * etc
5. restart the vms:
    * `bash start_vms.bash`
    * `virsh list --state-running`
6. if necessary rebuild ssh known_hosts
    * `bash rebuild_known_hosts.bash`
    * `virsh list --state-running`
    * `bash rebuild_known_hosts.bash`
    * `virsh list --state-running`
7. play with ansible

### Tear Down
1. shutdown the vms:
    * `bash shutdown_vms.bash`
    * `virsh list --state-running`
2. disconnect vms from bridges:
    * `bash disconnect_vms_from_bridges.bash`
3. undefine the vms:
    * `bash undefine_and_remove_vms.bash`
    * `virsh list --all`
4. undefine the bridges:
    * `bash remove_bridge_networks.bash`
    * `virsh net-list`

## Ansible Config
```cfg
# ~/.ansible.cfg
[defaults]
inventory = ~/router-lab/ansible/hosts.yml
```

## bashrc/environment
```cfg
# ~/.bashrc
export LIBVIRT_DEFAULT_URI="qemu+ssh://<user>@<host>/system"

alias ansible-pb=anspb
anspb() {
  ANS_DIR=~/router-lab/ansible/playbooks;
  echo Changing to "${ANS_DIR}" and executing: ansible-playbook "${@}"
  (cd $ANS_DIR || exit ; ansible-playbook "${@}")
}
```

## Ansible
1. configure the entire lab:
    * `ansible-pb build_out_routers.yml -K`
