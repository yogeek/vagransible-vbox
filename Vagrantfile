# -*- mode: ruby -*-
# vi: set ft=ruby :

# The following plugins are used and will be automatically installed
#  - vagrant-vbguest  : keep VirtualBox Guest Additions up to date
#  - vagrant-disksize : enable resizing disks in VirtualBox
#  - nugrant          : enable user specific configuration values (".vagrantuser" file)
required_plugins = %w(vagrant-vbguest nugrant vagrant-disksize)

if ARGV[0] == 'up'
  plugins_to_install = required_plugins.select { |plugin| not Vagrant.has_plugin? plugin }
  if not plugins_to_install.empty?
    puts "Installing plugins: #{plugins_to_install.join(' ')}"
    if system "vagrant plugin install #{plugins_to_install.join(' ')}"
      exec "vagrant #{ARGV.join(' ')}"
    else
      abort "Installation of one or more plugins has failed. Aborting."
    end
  end
end

# The following message will be displayed at the end of the process
$msg = <<MSG
------------------------------------------------------
Local Development environment.

A new VM has been created in VirtualBox. 
You can manage it either in VirtualBox or in command line with :
- `vagrant up` to start it
- `vagrant halt` to stop it
- `vagrant destroy` to delete it (if you want to build it again from scratch)

The Windows directory you have configured in '.vagrantuser' (vm > sharedfolder) is shared with the VM at the following path : "/sharedfolder".

Only chrome bookmarks have been imported automatically. 
For now, you must import Firefox bookmarks manually (bookmarks.html file has been copied into your home directory).

Some useful aliases are already available in the VM :
- `proxy_start`   : start proxy (cntlm+redsocks) to work at home
- `proxy_stop`    : stop proxy (cntlm+redsocks) to work at the office
- `proxy_status`  : check proxy status and internet connection

A SSH key pair have been created in "$HOME/.ssh".

A file explaining how to configure your GPG key to sign your git commits has been placed into your $HOME directory. 

------------------------------------------------------
MSG

VAGRANTFILE_API_VERSION = "2"

# Is GUI enabled : read GUI environment variable and convert it to boolean (true if not defined)
gui_enabled = ENV.fetch("GUI", "true").to_s == "true" 

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Pick a box to use:
  config.vm.box = "ubuntu/bionic64"
  config.vm.hostname = "vmdev"
  # Optional - enlarge disk (will also convert the format from VMDK to VDI):
  config.disksize.size = config.user.vm.disksize

  # Default values if the user does not define one in '.vagrantuser' file
  # Use 'vagrant user parameters' to check used parameters
  config.user.defaults = {
    "user" => {
      "password" => "password"
    },
    "cntlm" => {
      "username" => "uidxxxxx",
      "passntlmv2" => "XXXXXXXXXXXXXXX",
      "proxy" =>"proxy_url:proxy_port"
    },
    "vm" => {
      "name" => "vm.dev",
      "disksize" => "50GB",
      "memory" => 2048,
      "cpus" => 1,
      "sharedfolder" => "D:\\sharedfolder"
    }
  }

  # To fix IP address
  # config.vm.network :private_network, ip: "192.168.33.39"

  # Forward a port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Disable vbguest auto update because vbguest install guest additions right after the box started
  # and as we install VM desktop after with Ansible, some GUI features do not work well
  # So we disable auto install to instal guest addition with command line at the end of the provisionning
  config.vbguest.auto_update = false

  config.vm.provider :virtualbox do |v|
    v.name = config.user.vm.name
    v.memory = config.user.vm.memory
    v.cpus = config.user.vm.cpus
    v.gui = gui_enabled
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    # Bidirectionnal copy/paste
    v.customize ["modifyvm", :id, "--clipboard-mode", "bidirectional"]
    # Bidirectionnal drag & drop
    v.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
    # Enable the I/O APIC (required to use more than one virtual CPU in VM)
    v.customize ["modifyvm", :id, "--ioapic", "on"]
    # Disable audio
    v.customize ["modifyvm", :id, "--audio", "none"]
    v.customize ["modifyvm", :id, "--nestedpaging", "on"]
    # Disable PAE/NX (needed only for 32-bits guest that need more than 4GB of memory)
    v.customize ["modifyvm", :id, "--pae", "off"]
    # Enable Hardware Virtualization
    v.customize ["modifyvm", :id, "--hwvirtex", "on"]
    
    # On Intel CPUs, a hardware feature called Virtual Processor Identifiers (VPIDs) can greatly accelerate context switching 
    # by reducing the need for expensive flushing of the processor's Translation Lookaside Buffers (TLBs).
    # To enable these features for a VM, you use the VBoxManage modifyvm --vtxvpid and --largepages commands
    # v.customize ["modifyvm", :id, "--vtxvpid", "on"]
    # v.customize ["modifyvm", :id, "--largepages", "on"]

    # Add an empty optical drive (for Guest Additions)
    v.customize ["storageattach", :id, 
                "--storagectl", "IDE", 
                "--port", "0", "--device", "1", 
                "--type", "dvddrive", 
                "--medium", "emptydrive"]
    # To get the sound from the vm
    # vb.customize ["modifyvm", :id, '--audio', 'dsound', '--audiocontroller', 'ac97']
    # To get 2 monitors
    # vb.customize ["modifyvm", :id, "--monitorcount", "2"]
  end

  # Shared folder (read from .vagrantuser via nugrant plugin)
  config.vm.synced_folder config.user.vm.sharedfolder, "/sharedfolder", create: true, automount: true

  # Install libssl for Ansible (https://github.com/hashicorp/vagrant/issues/10914)
  config.vm.provision "shell",
    inline: "sudo apt-get update -y -qq && "\
      "export DEBIAN_FRONTEND=noninteractive && "\
      "sudo -E apt-get -q --option \"Dpkg::Options::=--force-confold\" --assume-yes install libssl1.1"

  # Provisioning : Run Ansible from the Vagrant VM
  config.vm.provision "ansible_local" do |ansible|
    ansible.install_mode        = "pip"
    ansible.compatibility_mode  = "2.0"
    ansible.playbook            = "provision/playbook.yml"
    ansible.provisioning_path   = "/vagrant"
    ansible.limit               = "all"
    ansible.verbose             = "true"
    # ansible.verbose             = "-vvv"
    # ansible.tags                = "role::packer"
    ansible.install             = true
    ansible.config_file         = "provision/ansible.cfg"

    # To install Ansible roles automatically
    ansible.galaxy_role_file  = "provision/requirements.yml"
    ansible.galaxy_roles_path = "/home/vagrant/.ansible/roles/"
    ansible.galaxy_command    = "ansible-galaxy install --role-file=%{role_file} --roles-path=%{roles_path}"

    # Pass .vagrantuser vars to ansible
    ansible.extra_vars = {
      ansible_python_interpreter: '/usr/bin/python3',
      user: {
        password: config.user.user.password
      },
      cntlm: {
        username: config.user.cntlm.username,
        passntlmv2: config.user.cntlm.passntlmv2,
        proxy: config.user.cntlm.proxy,
      }
    }

    config.vm.post_up_message = $msg
  
  end

end