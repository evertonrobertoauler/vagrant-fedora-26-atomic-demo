VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "kube-master" do |master|
    master.vm.box = "fedora/26-atomic-host"
    master.vm.network "private_network", ip: "192.168.50.100"
    master.vm.network "public_network", bridge: "enp2s0f0", ip: "10.10.0.60"
    master.vm.hostname = "kube-master"
    # master.vm.provision "shell", inline: "sudo rpm-ostree upgrade"
    master.vm.provision "file", source: "certs", destination: "/home/vagrant/ssl"
    master.vm.provision "shell", inline: "sudo rm -rf /etc/kubernetes/ssl"
    master.vm.provision "shell", inline: "sudo mv /home/vagrant/ssl /etc/kubernetes/ssl"
    master.vm.provision "shell", inline: "sudo chmod 0555 /etc/kubernetes/ssl -R"
    master.vm.provision "shell", path: "cfssl/setup-master.sh"
    # master.vm.provision "shell", inline: "sudo reboot"
  end

  (1..2).each do |i|
    config.vm.define "kube-worker-#{i}" do |worker|
      worker.vm.box = "fedora/26-atomic-host"
      worker.vm.network "private_network", ip: "192.168.50.10#{i}"
      worker.vm.network "public_network", bridge: "enp2s0f0", ip: "10.10.0.6#{i}"
      worker.vm.hostname = "kube-worker-#{i}"
      # worker.vm.provision "shell", inline: "sudo rpm-ostree upgrade"
      worker.vm.provision "file", source: "certs", destination: "/home/vagrant/ssl"
      worker.vm.provision "shell", inline: "sudo rm -rf /etc/kubernetes/ssl"
      worker.vm.provision "shell", inline: "sudo mv /home/vagrant/ssl /etc/kubernetes/ssl"
      worker.vm.provision "shell", inline: "sudo chmod 0555 /etc/kubernetes/ssl -R"
      worker.vm.provision "shell", path: "cfssl/setup-worker.sh"
      # worker.vm.provision "shell", inline: "sudo reboot"
    end
  end

end