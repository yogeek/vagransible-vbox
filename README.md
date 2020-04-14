# Automated VirtualBox Development environment creation for Windows host

This project aims to automate the creation of an Ubuntu virtual machine on Windows for development purpose.
Users can configured their desired tools via configuration files and launch the build of the machine.
This repo is a way to ease the maintenance and evolution of common development tools and everone is welcome to propose evolutions ! :-)

Tested with :

- VirtualBox 6.1.2, 6.1.4
- Vagrant : 2.2.2, 2.2.3, 2.2.7
- Windows 7, 10

## Prerequisites on your Windows host

- Install Vagrant for Windows : https://www.vagrantup.com/
- Install a bash terminal for Windows. Ex: Git bash => https://gitforwindows.org/ or VSCode integrated terminal
- Install VirtualBox : https://www.virtualbox.org/wiki/Downloads and set the default machine folder (`File > Preferences > General > Default Machine Folder`) to a disk where you have enough space (you can choose the size of your VM in the next part but consider 15Go as a minimum if you install all the proposed tools)
- Have a direct connection to internet

Troubleshooting : 
- if you have a Windows 7 or 8, you may encounter an error launching vagrant concerning the PowerShell version.
In this case, you can download a new PowerShell version here : https://social.technet.microsoft.com/wiki/contents/articles/21016.how-to-install-windows-powershell-4-0.aspx
- check that the VirtualBox installation directory in in your PATH : https://www.roelpeters.be/vboxmanage-is-not-recognized-and-how-to-solve-it/

## TL;DR

- Preparation :

  ```bash 
  # Open a terminal (Git Bash for example) in Windows and follow these steps
  git clone https://github.com/yogeek/vagransible-vbox.git && cd vagransible-vbox
  cp .vagrantuser.example .vagrantuser
  ```

  - Fill `.vagrantuser` with :
    - your personal information ('password' will be your system password to login to the VM)
    - cntlm informaton if you want to configure a proxy (*cf. below section to get CNTLM PassNTLMv2*)
    - VirtualBox options for your VM (you may want to choose at least 6GB if you want to develop with an IDE in your VM)
  - To configure your VM info and tools, you have 2 choices :
    - Modify default vars files with your own values :
      - Fill `provision/vars/all/main.yml` with your general information
      - Fill `provision/vars/all/tools.yml` with your desired tools
    - Create a `provision/vars/all/custom.yml` file in which you can override every variable from the above 2 files (this solution allows you to isolate your custom config and can avoid you merge headaches next time you pull an updated version of the repository). Variables defined in this file take precedence over the other vars files.
  - Options : if you already have one, you can keep your existing config files by overriding the default ones under `provision/files/` :  
    - copy your `.zshrc` to `provision/files/zshrc` (rename it 'zshrc' without the dot)
    - copy your chrome bookmarks to `provision/files/bookmarks.html`
    - copy your desktop wallpaper to `provision/files/wallpaper.jpg`
  - Launch `./build.sh` and go grab a cup of coffee (it takes a few minutes the first time...)

You must now have a brand new VM !

PS : Do not forget to change VM settings in VirtualBox (right-click on VM > Settings > System) if you did not already configure it in `.vagrantuser`, especially the RAM and CPU (pick at least 6GB for RAM).

## Useful tips

### CNTLM password hash (If you want to set a corporate proxy)

To get 'PassNTLMv2' value, open a command prompt in Windows in `C:\Program Files (x86)\Cntlm` (you can do this directly by going to the directory with the file explorer and Shift+RightClick > 'Open a command window here') and use the following comand :
`cntlm -I -H -d <DOMAIN> -u <UID>`

Copy the 'PassNTLMv2' field in the `.vagrantuser`.

### OFFICE and REMOTE Network connection  

In `utils` directory, you will find the two following scripts :

- disableProxy.bat : stop CNTLM and disable proxy in windows network connections
- enableProxy.bat  : start CNTLM and enable proxy in windows network connections

To launch these scripts easily, copy them to your Desktop for example and 'right-click' > 'Launch with admin privileges'.

Note : In office, network proxy is regularly forced back by IT (a few times a day), so if you have internet connection problems, launch the "disableProxy.bat" script.

Memo to switch between Office and Remote config :

- Office :
  * Windows : VPN off + launch disableProxy.bat
  * Linux VM : proxy_stop
- Remote :
  * Windows : VPN on + launch enableProxy.bat
  * Linux VM : proxy_start

### VScode extensions export

If you already have a VSCode installation with installed extensions, you can retrieve the list with the following command :
`code --list-extensions | xargs -L 1 echo code --install-extension`
You can then use this list to fill the vscode.extensions var in `vars/all/tools.yml`

### Ubuntu Keyring

The first time you launch Chrome, Ubuntu asks a "keyring" password : you can click "Continue" twice without entering any password to avoid having to type it each time.

### Convert an OVA to a Vagrant box

$ VBoxManage list vms
"vm-master Clone" {30dbbf71-4b98-44dd-a480-66244e33f571}

$ vagrant package --base 30dbbf71-4b98-44dd-a480-66244e33f571 --output vm-master-ova.box
==> 30dbbf71-4b98-44dd-a480-66244e33f571: Exporting VM...
==> 30dbbf71-4b98-44dd-a480-66244e33f571: Compressing package to: D:/Dev/Vagrant_UbuntuDev/vm-master-ova.box

$ vagrant box add vm-master-ova.box --name vm-master

$ vagrant box list

Source : https://github.com/crohr/ebarnouflant/issues/7

### SDK manager

All SDK can be managed with `sdk` tool : https://sdkman.io/, an easy way to install, remove, switch between multiple SDK candidates like Java, Maven, Scala, SBT, Groovy, etc.
[Usage](https://sdkman.io/usage) : `sdk <command> [candidate] [version]`
Memo :

- `sdk ls [candidate]`                : list sdk candidates (e.g. `sdk ls java`, `sdk ls scala`, `sdk ls maven`)
- `sdk install <candidate> [version]` : install sdk candidate (e.g. `sdk install java 10.0.2-open`)
- `sdk use <candidate> [version]`     : use a given version in the current terminal (e.g. `sdkuse scala 2.12.1`)
- `sdk default <candidate> [version]` : make a given version the default (e.g. `sdk default scala 2.11.6`)

## Troubleshooting

### Connection problem

This build is intended to work with a direct internet connection.
Indeed, with 'ansible_local' provisioner, vagrant first tries to download ansible from internet directly to the guest VM. As the VM just started, proxy is not yet configured so the internet access is not possible if a VPN is enabled.

### Python/Pip problems

`pyenv` and `pipenv` tools are the recommended way to manage python environments.
(cf. https://hackernoon.com/reaching-python-development-nirvana-bb5692adf30c)

_but

If you have an error like this when using pip as root :

```bash
root@vm# pip3 --version
Traceback (most recent call last):
  File "/usr/bin/pip3", line 9, in <module>
    from pip import main
ImportError: cannot import name 'main'
```

you can execute the following commands as a workaround :

```bash
python3 -m pip uninstall pip setuptools wheel
sudo apt-get -y --reinstall install  python3-setuptools python3-wheel python3-pip

python -m pip uninstall pip setuptools wheel
sudo apt-get -y --reinstall install python-setuptools python-wheel python-pip 
```

For details, cf. https://github.com/pypa/pip/issues/5599#issuecomment-416318017

### VBoxManage.exe: error: Unknown option

This code has been tested for the versions specified in the introduction. If you have installed a recent version of VirtualBox and/or Vagrant, you may encounter some issues due to deprecated options.

Example :

```bash
VBoxManage.exe: error: Unknown option: --clipboard
> Please fix this customization and try again.
```

This issue is referenced here and has been introduced with the latest VirtualBox version : https://github.com/hashicorp/vagrant/issues/11365
In this case, you can follow the indications provided in the issue and change change `--clipboard` to `--clipboard-mode`.

If you see these kind of error, please check your VirtualBox and Vagrant versions are compatible with the ones listed above.
