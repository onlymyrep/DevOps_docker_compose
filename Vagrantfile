Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.boot_timeout = 900

  config.vm.define "manager01" do |manager|
    manager.vm.hostname = "manager01"
    manager.vm.network "private_network", ip: "192.168.56.10"
    manager.vm.synced_folder ".", "/vagrant"
    manager.vm.provision "shell", path: "manager.sh"
    manager.vm.network "forwarded_port", guest: 8087, host: 8087
    manager.vm.network "forwarded_port", guest: 8081, host: 8081
    manager.vm.network "forwarded_port", guest: 9000, host: 9000
    manager.vm.provider "virtualbox" do |vb|
      vb.memory = 4096  
      vb.cpus = 3    
    end
  end

  config.vm.define "worker01" do |worker|
    worker.vm.hostname = "worker01"
    worker.vm.network "private_network", ip: "192.168.56.11"
    worker.vm.synced_folder ".", "/vagrant"
    worker.vm.provision "shell", path: "worker.sh"
    
    worker.vm.provider "virtualbox" do |vb|
      vb.memory = 2048 
      vb.cpus = 1 
    end
  end

  config.vm.define "worker02" do |worker|
    worker.vm.hostname = "worker02"
    worker.vm.network "private_network", ip: "192.168.56.12"
    worker.vm.synced_folder ".", "/vagrant"
    worker.vm.provision "shell", path: "worker.sh"
    
    worker.vm.provider "virtualbox" do |vb|
      vb.memory = 2048 
      vb.cpus = 1  
    end
  end
end