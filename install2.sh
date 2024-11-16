#!/bin/bash

# Clone the repository quietly
git clone --quiet https://github.com/KangQull/cloudsv2.git

# Move required files to the home directory
mv cloudsv2/backupv2 ~/
mv cloudsv2/hapus_nextcloud ~/
mv cloudsv2/menucloudv2 ~/
mv cloudsv2/ncloudv2 ~/
mv cloudsv2/restorev2 ~/
mv cloudsv2/settings3storage ~/

# Remove the cloned directory
rm -rf cloudsv2

# Make the scripts executable
chmod +x ~/restorev2
chmod +x ~/ncloudv2
chmod +x ~/menucloudv2
chmod +x ~/hapus_nextcloud
chmod +x ~/backupv2
chmod +x ~/settings3storage

# Move scripts to /usr/local/bin for easy access
mv ~/menucloudv2 /usr/local/bin
mv ~/hapus_nextcloud /usr/local/bin
mv ~/backupv2 /usr/local/bin
mv ~/ncloudv2 /usr/local/bin
mv ~/restorev2 /usr/local/bin
mv ~/settings3storage /usr/local/bin

# Add 'menuclouds' command to bashrc for auto-launch
echo "menucloudv2" >> ~/.bashrc

# Start the installation
menucloudv2
