#!/bin/sh

echo " # Backup do profile do boot2docker antigo"
DT=`date +"%Y-%m-%d_%Hh%Mmin"`
mv $HOME/.boot2docker/profile $HOME/.boot2docker/profile.$DT.bkp || echo " # Nenhum arquivo antigo de profile do boot2docker"

echo " # Informe um nome para sua customização: "
read VMNAME
echo " # Criando novo profile do boot2docker"
boot2docker config > $HOME/.boot2docker/profile

echo " # Seds no arquivo de profile do boot2docker - customizing"
sed -i '' -e"s/DiskSize = 20000/DiskSize = 25000/g" "$HOME/.boot2docker/profile"
sed -i '' -e"s/Memory = 2048/Memory = 4096/g" "$HOME/.boot2docker/profile"
sed -i '' -e"s/HostIP = \"192.168.59.3\"/HostIP = \"22.22.22.2\"/g" "$HOME/.boot2docker/profile"
sed -i '' -e"s/DHCPIP = \"192.168.59.99\"/DHCPIP = \"22.22.22.99\"/g" "$HOME/.boot2docker/profile"
sed -i '' -e"s/LowerIP = \"192.168.59.103\"/LowerIP = \"22.22.22.222\"/g" "$HOME/.boot2docker/profile"
sed -i '' -e"s/UpperIP = \"192.168.59.254\"/UpperIP = \"22.22.22.222\"/g" "$HOME/.boot2docker/profile"
sed -i '' -e"s/boot2docker-vm/boot2docker-$VMNAME-vm/g" "$HOME/.boot2docker/profile"

echo "Criando a nova vm do boot2docker"
boot2docker init
boot2docker up
$(boot2docker shellinit)

echo " # Backup do arquivo de exports se existir"
sudo mv /etc/exports /etc/exports.$DT.bkp || echo " # Nenhum arquivo /etx/exports encontrado"

echo " # Criando novo arquivo de exports no Mac"
echo "/Users -alldirs -mapall=$(whoami):staff 22.22.22.222" | sudo tee /etc/exports

echo " # Reiniciando daemon nfs no mac"
sudo nfsd checkexports && sudo nfsd restart

echo " # Criando arquivo de inicialização do boot2docker"
boot2docker ssh "sudo touch /var/lib/boot2docker/bootlocal.sh"

echo " # Acertando permissões do arquivo de inicialização do boot2docker"
boot2docker ssh "sudo chmod 755 /var/lib/boot2docker/bootlocal.sh"

echo " # Populando arquivo de inicialização do boot2docker com as configurações"
boot2docker ssh 'echo -e "#!/bin/bash" | sudo tee -a /var/lib/boot2docker/bootlocal.sh'
boot2docker ssh 'echo "sudo umount /Users" | sudo tee -a /var/lib/boot2docker/bootlocal.sh'
boot2docker ssh 'echo "sudo /usr/local/etc/init.d/nfs-client stop" | sudo tee -a /var/lib/boot2docker/bootlocal.sh'
boot2docker ssh 'echo "sudo /usr/local/etc/init.d/nfs-client start" | sudo tee -a /var/lib/boot2docker/bootlocal.sh'
boot2docker ssh 'echo "sudo mount 22.22.22.2:/Users /Users -o rw,async,noatime,rsize=32768,wsize=32768,proto=tcp,nfsvers=3" | sudo tee -a /var/lib/boot2docker/bootlocal.sh'

echo " # Baixando fix de certificados para boot2docker >= 1.7.0"
boot2docker ssh 'sudo curl -o /var/lib/boot2docker/profile https://gist.githubusercontent.com/garthk/d5a17007c277aa5c76de/raw/3d09c77aae38b4f2809d504784965f5a16f2de4c/profile'

echo " # Reiniciando boot2docker"
boot2docker down
boot2docker up

echo " # Fim - Boot2docker customizado"
