# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  if !Vagrant.has_plugin?("vagrant-reload")
     abort("vagrant-reload plugin has not been found. You can install it by `vagrant plugin install vagrant-reload`")
  end

  config.vm.define "stackinabox" do |stackinabox|
  if Vagrant.has_plugin?("vagrant-cachier")
     config.cache.scope = :box # cache at the base box level
   # setup yum cache
     config.cache.enable :yum
  else
     print "vagrant-cachier plugin has not been found."
     print "You can install it by `vagrant plugin install vagrant-cachier`"
  end
    # Freddys updated box with 260GB drive
    #
    stackinabox.vm.box = "freddy-centos7"
    # This is the original box from
    #stackinabox.vm.box = "puppetlabs/centos-7.0-64-nocm"#
    stackinabox.vm.hostname = "stackinabox"
    vmware = "vmware_workstation"
    stackinabox.vm.provider vmware do |vw|
      # Don't boot with headless mode
      #vw.gui = true

      vw.vmx["displayName"] = "stackinabox" # sets the name that virtual box will show in it's UI
      vw.vmx["numvcpus"] = "4" # set number of vcpus
      vw.vmx["memsize"] = "16384" # set amount of memory allocated vm memory
      vw.vmx["hypervisor.cpuid.v0"] = "FALSE"
      vw.vmx["mce.enable"] = "TRUE"
      vw.vmx["vhv.enable"] = "TRUE" # turn on host hardware virtualization extensions (VT-x|AMD-V)
    end
    # Ensure that VMWare Tools recompiles kernel modules
    # when we update the linux images
    $fix_vmware_tools_script = <<SCRIPT
    sed -i.bak 's/answer AUTO_KMODS_ENABLED_ANSWER no/answer AUTO_KMODS_ENABLED_ANSWER yes/g' /etc/vmware-tools/locations
    sed -i 's/answer AUTO_KMODS_ENABLED no/answer AUTO_KMODS_ENABLED yes/g' /etc/vmware-tools/locations
SCRIPT

    env_upgrade = ENV['UPGRADE']
    env_openstack = ENV['OPENSTACK']
    env_setup = ENV['SETUP']
    env_ucd=ENV['UCD']
    if env_upgrade.nil?
      if !env_setup.nil?
        stackinabox.vm.provision "shell", inline: $fix_vmware_tools_script
        stackinabox.vm.provision "shell", name: "setup networking", privileged: true, keep_color: false, path: "networks.sh"
        stackinabox.vm.provision :reload
        stackinabox.vm.provision "shell", name: "yum update", privileged: true,   inline: "yum update -y"
        stackinabox.vm.provision :reload
      end
      if !env_openstack.nil?
        stackinabox.vm.provision "shell", name: "run PackStack", privileged: true, keep_color: false, path: "packstack.sh"
        stackinabox.vm.provision "shell", name: "post install config", privileged: true, keep_color: false, path: "openstack-config.sh"
      end  
      if !env_ucd.nil?
          stackinabox.vm.provision "shell", name: "extend engine", privileged: true, keep_color: false, path: "extend-engine.sh"
          stackinabox.vm.provision "shell", name: "install RLKS", privileged: true, keep_color: false, path: "install-rlks.sh"
          stackinabox.vm.provision "shell", name: "install UCD", privileged: true, keep_color: false, path: "install-ucd.sh"
          stackinabox.vm.provision "shell", name: "install UCD agent relay", privileged: true, keep_color: false, path: "scripts/agent-relay-setup.sh"
          stackinabox.vm.provision "shell", name: "install Designer", privileged: true, keep_color: false, path: "install-designer.sh"
          stackinabox.vm.provision "shell", name: "add JKE app to UCD", privileged: true, keep_color: false, path: "addJKE.sh"
          # stackinabox.vm.provision "shell", name: "add UCDwUCD app to UCD", privileged: true, keep_color: false, path: "addUCDwUCD.sh"
          # stackinabox.vm.provision "shell", name: "add MobileFirst app to UCD", privileged: true, keep_color: false, path: "addMobileFirst.sh"
      end
    else
      if env_upgrade.include? "UCD"
        print "Upgrading UCD"
        stackinabox.vm.provision "shell", name: "upgrade UCD", privileged: true, keep_color: false, path: "upgrade-ucd.sh"
      end
      if env_upgrade.include? "engine"
        print "Upgrading engine"
        stackinabox.vm.provision "shell", name: "update engine", privileged: true, keep_color: false, path: "extend-engine.sh"
      end
      if env_upgrade.include? "designer"
        print "Upgrading designer"
        stackinabox.vm.provision "shell", name: "upgrade Designer", privileged: true, keep_color: false, path: "upgrade-designer.sh"
      end
    end
    stackinabox.vm.provision :reload
    stackinabox.vm.provision "shell", name: "All Done", privileged: true, keep_color: false, path: "alldone.sh"

  end

end
