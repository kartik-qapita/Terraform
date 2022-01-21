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

# Setting up the Software Components
# Installing - Docker, SEQ-Data, MongoDB, EventStore, Nginx, .NET SDK 6.0
# DOCKER
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Install SEQ
sudo docker image pull datalust/seq
sudo docker container create -p 5341:5341 -p 8081:80 \
    -v /seq-data:/data \
    -e ACCEPT_EULA=y \
    --name q-seq-node datalust/seq
sudo docker container start q-seq-node

# Installing MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
sudo apt-get update
sudo apt-get install -y mongodb-org
# You can verify that mongodb is installed by the following command
type -a mongod
# Configuration file of mongo is in /etc/mongod.conf, set storage.dbPath to /mongodb-data/db
# Set storage.directoryPerDB to true, set systemLog.path to /mongodb-data/log/mongod.log
sudo mkdir -p /mongodb-data/db /mongodb-data/log /mongodb-data/journal
sudo ln -s /mongodb-data/journal /mongodb-data/db/journal
# Change ownership of /mongodb-data folder to mongodb user
sudo chown -R mongodb:mongodb /mongodb-data
# Start mongodb
sudo systemctl start mongod
# To check if mongodb is running
sudo systemctl status mongod
# Make mongod start automatically when machine starts
sudo systemctl enable mongod

# Installing DotNet-6.0
wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update; \
  sudo apt-get install -y apt-transport-https && \
  sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-6.0

# Install EventStoreDB
# Install aws cli (to download EventStoreDB from s3 folder)
sudo apt install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Download the eventstore and related files from aws s3 bucket
mkdir -p ~/machine-setup/eventstore ~/machine-setup/certificates
aws s3 cp s3://qapita-development/EventStore ~/machine-setup/eventstore --recursive
aws s3 cp s3://qapita-development/certificates ~/machine-setup/certificates --recursive
sudo dpkg -i ~/machine-setup/eventstore/EventStore-Commercial-Linux-v20.6.1-2.ubuntu-18.04.deb
sudo mkdir eventstoredb
# Make eventstore user as the owner of /eventstore
sudo cp ~/machine-setup/eventstore/eventstore-1.pfx /etc/eventstore
sudo cp ~/machine-setup/eventstore/eventstore.conf /etc/eventstore
sudo cp ~/machine-setup/certificates/qapita-CA.crt /usr/local/share/ca-certificates
sudo update-ca-certificates
sudo chown -R eventstore:eventstore /etc/eventstore
sudo chown -R eventstore:eventstore /eventstoredb

# Configure the eventstore in /etc/eventstore/eventstore.conf
# Replace eventstore.conf contents with the following lines
echo '
RunProjections: All
ClusterSize: 1
MemDb: False
StartStandardProjections: True
EnableExternalTcp: True
Db: /eventstoredb-data/db
Log: /eventstoredb-data/log
EnableAtomPubOverHttp: True
ExtIp: 0.0.0.0
IntIp: 0.0.0.0
CertificateFile: /etc/eventstore/eventstore-1.pfx
CertificatePassword: qapita
TrustedRootCertificatesPath: /usr/local/share/ca-certificates/ ' | sudo tee -a /etc/eventstore/eventstore.conf

sudo cp ~/machine-setup/certificates/qapita-CA.crt /usr/local/share/ca-certificates
sudo update-ca-certificates
# Start the eventstore
sudo systemctl start eventstore
# Check status of eventstore
sudo systemctl status eventstore
# Make eventstore start automatically when the machine starts
sudo systemctl enable eventstore

# Installing NGINX 1.20.2
(cat << EOF
deb https://nginx.org/packages/ubuntu/ $(lsb_release -cs) nginx
deb-src https://nginx.org/packages/ubuntu/ $(lsb_release -cs) nginx
EOF
) | sudo tee /etc/apt/sources.list.d/nginx.list
echo
sudo apt-get update
echo
key=ABF5BD827BD9BF62
echo
# If key error, copy the key to environment variable "key" and run the below command ABF5BD827BD9BF62
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $key
sudo apt-get update
sudo apt-get remove -y nginx
sudo apt install -y nginx
echo 'Software Installation Completed'
# Softwares Installation Completed.
