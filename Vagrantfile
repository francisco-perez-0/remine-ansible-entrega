# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  config.vm.provider "virtualbox" do |v|
      v.memory = 2048
  end

  config.vm.network "forwarded_port",
    guest: 80, host: 8888, host_ip: "127.0.0.1"

  #config.vm.provision "shell", inline: "ansible-galaxy install bbatsche.mysql"

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y acl
  SHELL
  
  config.vm.provision "ansible_local" do |ansible|
    install_mode = :default
    ansible.playbook = "playbook.yml"
    ansible.galaxy_role_file = "requirements.yml"
  end
end
