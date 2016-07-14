Vagrant.configure(2) do |config|
  config.vm.box = "imartinezortiz/trusty64-docker"
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--cpus"  , "2"   ]
    vb.customize ["modifyvm", :id, "--memory"  , "3072"   ]
  end
end
