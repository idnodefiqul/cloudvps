#!/bin/bash

# Clone the repository quietly
git clone --quiet https://github.com/KangQull/cloudsinstaller.git

# Move required files to the home directory
mv cloudsinstaller/menuclouds ~/
mv cloudsinstaller/removenextcloud ~/
mv cloudsinstaller/settings3storage ~/
mv cloudsinstaller/removeowncloud ~/
mv cloudsinstaller/uploadsetting ~/
mv cloudsinstaller/fixsindex ~/
mv cloudsinstaller/Restorenexcloud ~/
mv cloudsinstaller/BackupNexcloud ~/

# Remove the cloned directory
rm -rf cloudsinstaller

# Make the scripts executable
chmod +x ~/menuclouds
chmod +x ~/removenextcloud
chmod +x ~/settings3storage
chmod +x ~/removeowncloud
chmod +x ~/uploadsetting
chmod +x ~/fixsindex
chmod +x ~/BackupNexcloud
chmod +x ~/Restorenexcloud

# Move scripts to /usr/local/bin for easy access
mv ~/menuclouds /usr/local/bin
mv ~/removenextcloud /usr/local/bin
mv ~/settings3storage /usr/local/bin
mv ~/removeowncloud /usr/local/bin
mv ~/uploadsetting /usr/local/bin
mv ~/fixsindex /usr/local/bin
mv ~/BackupNexcloud /usr/local/bin
mv ~/Restorenexcloud /usr/local/bin

# Add 'menuclouds' command to bashrc for auto-launch
echo "menuclouds" >> ~/.bashrc

# Start the installation
menuclouds
