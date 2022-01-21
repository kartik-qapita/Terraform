#! /bin/bash
sudo cp /etc/fstab /etc/fstab.orig
#SEQ-DRIVE: MOUNTING SETUP
export SEQ_DEVICE=/dev/$(lsblk -n | awk 'NR==8 {print $1}')
sudo mkdir -p /seqdata
yes | sudo mkfs -t ext4 $SEQ_DEVICE
sudo e2label $SEQ_DEVICE "q-seqdata"
echo 'LABEL=q-seqdata        /seqdata ext4  defaults,nofail          0 2' | sudo tee -a /etc/fstab
sudo mount -a
echo
#MONGODB-DRIVE: MOUNTING SETUP
export MONGODB_DEVICE=/dev/$(lsblk -n | awk 'NR==9 {print $1}')
sudo mkdir -p /mongodb-data
yes | sudo mkfs -t ext4 $MONGODB_DEVICE
sudo e2label $MONGODB_DEVICE "q-mongodb-data"
echo 'LABEL=q-mongodb-data        /mongodb-data ext4  defaults,nofail          0 2' | sudo tee -a /etc/fstab
sudo mount -a
echo
#EVENTSTOREDB-DRIVE: MOUNTING SETUP
export EVENTSDB_DEVICE=/dev/$(lsblk -n | awk 'NR==10 {print $1}')
sudo mkdir -p /eventstore
yes | sudo mkfs -t ext4 $EVENTSDB_DEVICE
sudo e2label $EVENTSDB_DEVICE "q-eventstore"
echo 'LABEL=q-eventstore        /eventstore ext4  defaults,nofail          0 2' | sudo tee -a /etc/fstab
sudo mount -a
echo
#VAR-DRIVE: MOUNTING SETUP
export VAR_DEVICE=/dev/$(lsblk -n | awk 'NR==6 {print $1}')
echo Setting up var disk
yes | sudo mkfs -t ext4 $VAR_DEVICE
sudo e2label $VAR_DEVICE "q-var"
shopt -s dotglob
sudo mkdir -p /mnt/var
sudo mount $VAR_DEVICE /mnt/var
sudo rsync -aulvXpogtr /var/* /mnt/var
sudo mv /var /var.old
sudo mkdir /var
sudo umount /mnt/var
echo 'LABEL=q-var             /var     ext4   defaults,nofail         0 2' | sudo tee -a /etc/fstab
sudo mount -a
echo
#HOME-DRIVE: MOUNTING COMMANDS
export HOME_DEVICE=/dev/$(lsblk -n | awk 'NR==7 {print $1}')
#Home Disk: Setup Commands
echo Setting up home disk
yes | sudo mkfs -t ext4 $HOME_DEVICE
echo 'executed home mkfs step'>>/tmp/deploy.log
sudo e2label $HOME_DEVICE "q-home"
shopt -s dotglob
sudo mkdir -p /mnt/home
sudo mount $HOME_DEVICE /mnt/home
echo 'executed mount $Homedevice step'>>/tmp/deploy.log
sudo rsync -aulvXpogtr /home/* /mnt/home
sudo mv /home /home.old
sudo mkdir /home
sudo umount /mnt/home
echo 'executed home commands step'>>/tmp/deploy.log
echo 'LABEL=q-home             /home     ext4   defaults,nofail         0 2' | sudo tee -a /etc/fstab
sudo mount -a
echo
sudo mount -a
echo
#INSTALL-SOFTWARE: COMMANDS
#NGINX-INSTALLATION:
sudo apt install -y nginx
sudo service nginx start
echo
