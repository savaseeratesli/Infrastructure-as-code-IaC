Vagrant.configure("2") do |config|
  nodes = [
    { name: "master", ip: "192.168.1.10" },
    { name: "worker1", ip: "192.168.1.11" },
    { name: "worker2", ip: "192.168.1.12" },
    { name: "control-node", ip: "192.168.1.13" },
    { name: "managed-node", ip: "192.168.1.14" }
  ]

  nodes.each do |node|
    config.vm.define node[:name] do |node_config|
      node_config.vm.box = "centos/stream9"
      node_config.vm.hostname = node[:name]
      node_config.vm.network "public_network", ip: node[:ip], bridge: "eth0"
      
      node_config.vm.provider "virtualbox" do |vb|
        vb.name = node[:name]
        vb.memory = "2048"
        vb.cpus = 2
        vb.customize ["modifyvm", :id,
          "--boot1", "floppy",
          "--boot2", "dvd",
          "--boot3", "disk",
          "--nestedpaging", "on",
          "--pae", "on",
          "--hwvirtex", "on",
          "--graphicscontroller", "vmsvga",
          "--vram", "16",
          "--accelerate3d", "off",
          "--rtcuseutc", "on",
          "--usb", "off"
        ]
        vb.customize ["storageattach", :id, "--storagectl", "IDE", "--port", 1, "--device", 0, "--type", "dvddrive", "--medium", "emptydrive"]
        vb.customize ["storagectl", :id, "--name", "SATA", "--add", "sata"]
        vb.customize ["createhd", "--filename", "centos9stream.vdi", "--size", 20480]
        vb.customize ["storageattach", :id, "--storagectl", "SATA", "--port", 0, "--device", 0, "--type", "hdd", "--medium", "centos9stream.vdi"]
      end

      node_config.vm.synced_folder "C:\\Users\\savas\\Desktop\\sanalPaylasim", "/opt/", create: true
      
      node_config.vm.provision "shell", inline: <<-SHELL
        localectl set-locale LANG=tr_TR.UTF-8
        dnf -y remove @"Server with GUI"
      SHELL
    end
  end
end
